import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/workout_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Theme colors
  static const Color _bgColor = Color(0xFF11111B);
  static const Color _cardColor = Color(0xFF1E1E2E);
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _accentColor = Color(0xFF00B894);

  // Settings State
  bool _isLoading = true;
  String _unit = 'kg';
  double _barbellWeight = 20.0;
  int _restSeconds = 60;
  final WorkoutRepository _workoutRepository = WorkoutRepository();

  // Firebase Auth User
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      _currentUser = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    final savedUnit = prefs.getString('user_unit') ?? 'kg';

    final dynamic weightVal = prefs.get('user_barbell_weight');
    double loadedWeight = 20.0;
    if (weightVal is num) {
      loadedWeight = weightVal.toDouble();
    } else if (weightVal is String) {
      loadedWeight =
          double.tryParse(weightVal.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 20.0;
    }

    final loadedRest = prefs.getInt('default_rest_seconds') ?? 60;

    if (mounted) {
      setState(() {
        _unit = savedUnit;
        _barbellWeight = loadedWeight;
        _restSeconds = loadedRest;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUnit(String newUnit) async {
    setState(() {
      _unit = newUnit;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_unit', newUnit);
  }

  Future<void> _updateBarbellWeight(double newWeight) async {
    setState(() {
      _barbellWeight = newWeight;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_barbell_weight', newWeight);
  }

  Future<void> _updateRestSeconds(int seconds) async {
    setState(() {
      _restSeconds = seconds;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('default_rest_seconds', seconds);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            )
          : ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                // SECTION 1: UNITS
                _buildSectionHeader('Units'),
                const SizedBox(height: 10),
                _buildCardContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weight Unit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Used for exercise logs & max estimates',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            _buildUnitToggleButton('kg'),
                            _buildUnitToggleButton('lbs'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION 2: BARBELL WEIGHT
                _buildSectionHeader('Barbell Weight'),
                const SizedBox(height: 10),
                _buildCardContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Default Barbell Weight',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Empty Olympic or standard bar',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: _cardColor,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<double>(
                            value: [20.0, 15.0, 10.0].contains(_barbellWeight)
                                ? _barbellWeight
                                : 20.0,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _primaryColor,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            onChanged: (double? newValue) {
                              if (newValue != null) {
                                _updateBarbellWeight(newValue);
                              }
                            },
                            items: const [
                              DropdownMenuItem<double>(
                                value: 20.0,
                                child: Text('20 kg'),
                              ),
                              DropdownMenuItem<double>(
                                value: 15.0,
                                child: Text('15 kg'),
                              ),
                              DropdownMenuItem<double>(
                                value: 10.0,
                                child: Text('10 kg'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION 3: REST TIMER DEFAULT
                _buildSectionHeader('Rest Timer Default'),
                const SizedBox(height: 10),
                _buildCardContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rest Duration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Default timer between sets',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: _cardColor,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: [60, 90, 120, 180].contains(_restSeconds)
                                ? _restSeconds
                                : 60,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _primaryColor,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                _updateRestSeconds(newValue);
                              }
                            },
                            items: const [
                              DropdownMenuItem<int>(
                                value: 60,
                                child: Text('60 sec'),
                              ),
                              DropdownMenuItem<int>(
                                value: 90,
                                child: Text('90 sec'),
                              ),
                              DropdownMenuItem<int>(
                                value: 120,
                                child: Text('120 sec'),
                              ),
                              DropdownMenuItem<int>(
                                value: 180,
                                child: Text('180 sec'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION 4: DATA MANAGEMENT
                _buildSectionHeader('Data Management'),
                const SizedBox(height: 10),
                _buildCardContainer(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.file_download_outlined, color: _primaryColor),
                    ),
                    title: const Text(
                      'Export Workout Data',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text(
                      'Export all workouts as CSV (Excel, Sheets, Hevy)',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                    onTap: _showExportDialog,
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION 5: ACCOUNT
                _buildSectionHeader('Account'),
                const SizedBox(height: 10),
                _buildCardContainer(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _primaryColor.withOpacity(0.2),
                            child: const Icon(
                              Icons.person_rounded,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentUser?.email ??
                                      _currentUser?.phoneNumber ??
                                      'Not Logged In',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentUser?.uid != null
                                      ? 'UID: ${_currentUser!.uid}'
                                      : 'Guest Account',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.white.withOpacity(0.08)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                          label: const Text(
                            'Sign Out',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: _accentColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildUnitToggleButton(String unitLabel) {
    final isSelected = _unit == unitLabel;
    return GestureDetector(
      onTap: () => _updateUnit(unitLabel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          unitLabel,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showExportDialog() {
    final workouts = _workoutRepository.getWorkoutHistory();
    final csvContent = _workoutRepository.exportWorkoutsToCsv(workouts);

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'EXPORT WORKOUTS (CSV)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${workouts.length} workouts formatted for Excel, Google Sheets, Strong, or Hevy.',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      csvContent,
                      style: const TextStyle(
                        color: _accentColor,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(ctx);
                    await Clipboard.setData(ClipboardData(text: csvContent));
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('CSV copied to clipboard! Ready to paste into Sheets or Excel.'),
                        backgroundColor: _accentColor,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, color: Colors.white),
                  label: const Text(
                    'Copy CSV to Clipboard',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
