import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class _PmSection {
  final String title;
  final List<String> items;

  const _PmSection(this.title, this.items);
}

// Digitized from the Sandy Preventative Maintenance checklist. Reference-only
// utility — nothing here is sent to the API, it just gives the tech a page to
// tap through while doing a PM.
const List<_PmSection> _pmSections = [
  _PmSection('Deck', [
    'Stow control box on deck (make sure cord is on deck and wire tied)',
    'Pull out deck',
    'Sweep off debris before pressure washing',
    'Check rail bolts',
    'Check spring pins',
    'Check safety chain',
    'Check deck oars',
    'Check head banger',
    'Check instruction box',
    'Check outlet',
    'Check wire ties',
  ]),
  _PmSection('Lower Box', [
    'Check up and down (all the way) — noisy? smooth? good speed?',
    'Check emergency down',
    'Check charger endcap',
    'Check key',
    'Check safety pin on hydraulic cylinder',
  ]),
  _PmSection('Control Box', [
    'Check up and down',
    'Check forward and back — left and right',
    'Check travel when up (should be turtle speed)',
    'Check horn',
    'Check cannon plug',
  ]),
  _PmSection('Battery Care', [
    'Pull out both sides',
    'Load test all 4 batteries',
    'Check water level',
    'Check corrosion',
    'Check battery trays and doors (broken trays, missing or loose bolts)',
    'Replace wire connectors as needed',
    'Spray on battery coat as needed',
    'Check brake release working',
  ]),
  _PmSection('Tires', [
    'Inspect for screws and debris',
    'Check wheel seals for moisture',
    'Turn cylinder for hydraulic leaks and mounting bolts',
    'Inspect drive motor',
    'Check spindles for wear and brushes',
  ]),
  _PmSection('Beautify', [
    'Clean, wipe down, scrape as you go and before power washing',
    'Power wash (if needed)',
    'Work from top to bottom — raise lift after upper section',
    'Replace decals and serial numbers as needed',
    'Paint if necessary',
    'Verify serial number',
  ]),
  _PmSection('Finish', [
    'Finish PM card — record & initial, star all work needed',
    'Put lift to the back of the line and plug in',
  ]),
];

class PmChecklistScreen extends StatefulWidget {
  const PmChecklistScreen({super.key});

  @override
  State<PmChecklistScreen> createState() => _PmChecklistScreenState();
}

class _PmChecklistScreenState extends State<PmChecklistScreen> {
  final List<List<bool>> _checked = [
    for (final section in _pmSections)
      List<bool>.filled(section.items.length, false),
  ];

  int get _totalItems =>
      _pmSections.fold(0, (sum, s) => sum + s.items.length);

  int get _checkedCount =>
      _checked.fold(0, (sum, section) => sum + section.where((c) => c).length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.mainBackground,
        iconTheme: const IconThemeData(color: AppColors.yellow),
        title: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                AppColors.yellow,
                AppColors.green,
                AppColors.red,
              ],
            ).createShader(bounds);
          },
          child: Text(
            "PM Checklist",
            style: GoogleFonts.permanentMarker(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              '$_checkedCount / $_totalItems checked',
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: _pmSections.length,
              itemBuilder: (context, sectionIndex) {
                final section = _pmSections[sectionIndex];

                return Card(
                  color: AppColors.main,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          '${sectionIndex + 1}. ${section.title}',
                          style: const TextStyle(
                            color: AppColors.yellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      for (int i = 0; i < section.items.length; i++)
                        CheckboxListTile(
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.green,
                          checkColor: AppColors.main,
                          value: _checked[sectionIndex][i],
                          onChanged: (value) {
                            setState(() {
                              _checked[sectionIndex][i] = value ?? false;
                            });
                          },
                          title: Text(
                            section.items[i],
                            style: TextStyle(
                              color: _checked[sectionIndex][i]
                                  ? AppColors.green
                                  : Colors.white,
                              decoration: _checked[sectionIndex][i]
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
