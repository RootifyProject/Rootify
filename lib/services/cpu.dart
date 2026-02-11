/*
 * Copyright (C) 2026 Rootify - Aby - FoxLabs
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ---- SYSTEM ---
import 'dart:async';

// ---- LOCAL ---
import '../utils/app_logger.dart';
import '../services/shell_services.dart';

// ---- MAJOR ---
// CPU Data Models for Performance Tracking
// --- Sub
// Individual Core Metrics
class CpuCore {
  final int id;
  int freq;
  bool isOnline;
  double temp;

  CpuCore(this.id, {this.freq = 0, this.isOnline = true, this.temp = 0.0});

  // Comment: Direct MHz conversion from the raw frequency (KHz)
  int get mhz => freq ~/ 1000;
}

// --- Sub
// Logical Core Groups (Policies)
class CpuCluster {
  final int id;
  final List<int> coreIds;
  String governor;

  CpuCluster(this.id, this.coreIds, {this.governor = 'Unknown'});
}

// --- Sub
// Consolidated System Snapshot
class CpuSnapshot {
  final List<CpuCore> cores;
  final List<CpuCluster> clusters;
  final double packageTemp;
  final double totalLoad;
  final DateTime timestamp;

  CpuSnapshot(this.cores, this.clusters,
      {this.packageTemp = 0.0, this.totalLoad = 0.0})
      : timestamp = DateTime.now();
}

// ---- MAJOR ---
// Heartbeat Engine for Processor & Thermal Monitoring
class CpuMonitoringService {
  // --- Sub
  // Singleton Pattern
  static final CpuMonitoringService _instance =
      CpuMonitoringService._internal();
  factory CpuMonitoringService() => _instance;
  CpuMonitoringService._internal();

  // --- Sub
  // Lifecycle Handlers
  void init(ShellService shell) {
    _shell = shell;
  }

  // --- Sub
  // Private Logic Containers
  Timer? _timer;
  final _controller = StreamController<CpuSnapshot>.broadcast();
  ShellService? _shell;
  double _lastLoad = 0.0;

  // Comment: Cache object references to avoid reallocation
  final List<CpuCore> _cores = [];
  final List<CpuCluster> _clusters = [];

  // Comment: Cache paths to avoid String interpolation every tick
  final Map<int, String> _coreFreqPaths = {};
  final Map<int, String> _coreOnlinePaths = {};
  final Map<int, String> _clusterGovPaths = {};
  final List<String> _thermalZonePaths = []; // All CPU/SoC temp paths
  String? _packageTempPath;

  bool _initialized = false;

  // --- Sub
  // Public Accessors
  Stream<CpuSnapshot> get stats => _controller.stream;

  // --- Sub
  // Execution Control
  Future<void> start() async {
    if (_timer != null || _shell == null) return;
    if (!_initialized) await _initTopology();

    // Comment: Start tick (1 second for more responsive visual feedback)
    // Reduce CPU Load fetch frequency to every 2 ticks to save battery/overhead
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => _update(t.tick));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  // --- Sub
  // Data Aggregation Tick
  Future<void> _update(int tick) async {
    if (!_initialized || _controller.isClosed) return;

    try {
      // Comment: Fetch CPU Load (Expensive, run every 2 seconds)
      double load = 0.0;
      if (tick % 2 == 0) {
        final cpuShell = _shell!.getCpuShell();
        load = await cpuShell.getCpuLoad();
        _lastLoad = load;
      } else {
        load = _lastLoad;
      }

      // Comment: Run other updates in parallel for efficiency
      await Future.wait([
        _updateCoresParallel(),
        _updateClustersParallel(),
        _updateThermalParallel(),
      ]);

      if (!_controller.isClosed) {
        _controller.add(CpuSnapshot(
          _cores
              .map((c) => CpuCore(c.id,
                  freq: c.freq, isOnline: c.isOnline, temp: c.temp))
              .toList(),
          _clusters
              .map((c) => CpuCluster(c.id, c.coreIds, governor: c.governor))
              .toList(),
          packageTemp: await _calculatePackageTemp(),
          totalLoad: load,
        ));
      }
    } catch (e) {
      // Comment: Suppress spam during transient errors
    }
  }

  // --- Sub
  // Topology Discovery Engine
  Future<void> _initTopology() async {
    try {
      // Comment: 1. DETECT CORES
      _cores.clear();
      int coreIdx = 0;
      while (true) {
        final check = await _shell!.exec(
            "test -d /sys/devices/system/cpu/cpu$coreIdx && echo 'YES' || echo 'NO'");
        if (!check.contains("YES")) break;

        _cores.add(CpuCore(coreIdx));
        _coreFreqPaths[coreIdx] =
            '/sys/devices/system/cpu/cpu$coreIdx/cpufreq/scaling_cur_freq';
        _coreOnlinePaths[coreIdx] =
            '/sys/devices/system/cpu/cpu$coreIdx/online';
        coreIdx++;
      }

      // Comment: 2. DETECT CLUSTERS
      _clusters.clear();
      final policiesRaw = await _shell!
          .exec("ls -d /sys/devices/system/cpu/cpufreq/policy* 2>/dev/null");
      final policies =
          policiesRaw.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

      for (final pPath in policies) {
        final pName = pPath.split('/').last;
        final pId = int.tryParse(pName.replaceAll('policy', '')) ?? 0;
        final affectedPath = '$pPath/affected_cpus';

        final content = await _shell!.exec("cat $affectedPath 2>/dev/null");
        if (content.isNotEmpty) {
          final ids = _parseCpuList(content);
          _clusters.add(CpuCluster(pId, ids));
          _clusterGovPaths[pId] = '$pPath/scaling_governor';
        }
      }

      // Comment: 3. DETECT THERMAL ZONES
      _thermalZonePaths.clear();
      _packageTempPath = null;

      final thermalZonesRaw = await _shell!
          .exec("ls -d /sys/class/thermal/thermal_zone* 2>/dev/null");
      final zones = thermalZonesRaw
          .split(RegExp(r'\s+'))
          .where((z) => z.isNotEmpty)
          .toList();

      final cpuKeywords = [
        'cpu',
        'soc',
        'pkg_temp',
        'cpu-vbb-sum',
        'case_temp',
        'quiet_therm',
        'soc_therm'
      ];

      for (final zPath in zones) {
        try {
          final type = (await _shell!.exec("cat $zPath/type 2>/dev/null"))
              .trim()
              .toLowerCase();
          final tempPath = '$zPath/temp';

          if (type.contains('pkg_temp') ||
              type.contains('soc') ||
              type.contains('soc_therm')) {
            _packageTempPath = tempPath;
          }

          if (cpuKeywords.any((k) => type.contains(k))) {
            _thermalZonePaths.add(tempPath);
          }
        } catch (_) {}
      }

      _initialized = true;
      logger.d(
          "CPU Info: Topology initialized (${_cores.length} cores, ${_clusters.length} clusters)");
    } catch (e, st) {
      logger.e("CPU Info: Topology init failed", e, st);
    }
  }

  // --- Sub
  // Parallel Data Acquisition
  Future<void> _updateCoresParallel() async {
    final onlineCmd = _cores
        .map((c) => "cat ${_coreOnlinePaths[c.id]} 2>/dev/null")
        .join("; echo '---'; ");
    final freqCmd = _cores
        .map((c) => "cat ${_coreFreqPaths[c.id]} 2>/dev/null")
        .join("; echo '---'; ");

    final results = await Future.wait([
      _shell!.exec(onlineCmd),
      _shell!.exec(freqCmd),
    ]);

    final onlineVals = results[0].split('---');
    final freqVals = results[1].split('---');

    for (int i = 0; i < _cores.length; i++) {
      if (i < onlineVals.length) {
        final val = onlineVals[i].trim();
        _cores[i].isOnline = val == '1' || val.isEmpty;
      }
      if (i < freqVals.length) {
        _cores[i].freq = int.tryParse(freqVals[i].trim()) ?? 0;
      }
    }
  }

  Future<void> _updateClustersParallel() async {
    final govCmd = _clusters
        .map((c) => "cat ${_clusterGovPaths[c.id]} 2>/dev/null")
        .join("; echo '---'; ");
    final output = await _shell!.exec(govCmd);
    final vals = output.split('---');

    for (int i = 0; i < _clusters.length; i++) {
      if (i < vals.length) {
        _clusters[i].governor = vals[i].trim();
      }
    }
  }

  // --- Sub
  // Thermal Aggregator
  Future<double> _calculatePackageTemp() async {
    if (_packageTempPath != null) {
      try {
        final val = await _shell!.exec("cat $_packageTempPath 2>/dev/null");
        return _normalizeTemp(int.tryParse(val.trim()) ?? 0);
      } catch (_) {}
    }

    if (_thermalZonePaths.isNotEmpty) {
      final cmd = _thermalZonePaths
          .map((p) => "cat $p 2>/dev/null")
          .join("; echo '---'; ");
      final output = await _shell!.exec(cmd);
      final vals = output.split('---');

      double maxTemp = 0.0;
      for (final v in vals) {
        final t = _normalizeTemp(int.tryParse(v.trim()) ?? 0);
        if (t > maxTemp) maxTemp = t;
      }
      return maxTemp;
    }

    return 0.0;
  }

  Future<void> _updateThermalParallel() async {
    final currentPackageTemp = await _calculatePackageTemp();
    if (currentPackageTemp > 0) {
      for (var core in _cores) {
        core.temp = currentPackageTemp;
      }
    }
  }

  // --- Sub
  // Normalization Helpers
  double _normalizeTemp(int raw) {
    double temp = raw.toDouble();
    if (temp > 15000) temp /= 1000.0;
    if (temp > 150) temp /= 10.0;
    return (temp >= 0 && temp <= 120) ? temp : 0.0;
  }

  List<int> _parseCpuList(String content) {
    final result = <int>[];
    final parts = content.trim().split(RegExp(r'[,\s]+'));

    for (var part in parts) {
      if (part.contains('-')) {
        final range = part.split('-');
        if (range.length == 2) {
          final start = int.tryParse(range[0]) ?? 0;
          final end = int.tryParse(range[1]) ?? 0;
          for (int i = start; i <= end; i++) {
            result.add(i);
          }
        }
      } else {
        final val = int.tryParse(part);
        if (val != null) result.add(val);
      }
    }
    return result;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

// ---- MAJOR ---
// Global Instances
final cpuMonitor = CpuMonitoringService();
