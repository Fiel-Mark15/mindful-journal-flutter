import 'package:flutter/material.dart';
import '../widgets/journal_components.dart';

// These documents describe the current device-local implementation.
// Before public/production release, review and update for actual collection,
// accounts, analytics, cloud, AI, advertising, and third-party SDK use.
// TODO(developer): Replace the contact placeholder with verified developer
// identity and a real support contact before distributing the app publicly.
const developerContact =
    'Developer and support contact details have not been provided for this educational build.';
const legalEffectiveDate = 'October 11, 2026';

enum LegalDocument { privacy, terms, overview }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});
  final LegalDocument document;
  @override
  Widget build(BuildContext context) {
    final title = switch (document) {
      LegalDocument.privacy => 'Privacy Policy',
      LegalDocument.terms => 'Terms of Use',
      LegalDocument.overview => 'Privacy overview',
    };
    final sections = switch (document) {
      LegalDocument.overview => <(String, String)>[
        (
          'A journal for this session',
          'Journal entries, tasks, imported image previews, drawings, profile details, favorites and preferences are saved on this device. Closing a screen does not clear them. They remain available when you reopen the app.',
        ),
        (
          'No connected account',
          'This build has no account system, database, cloud synchronization, AI API or journal-upload service.',
        ),
        (
          'Your controls',
          'Clear this session’s data in Settings removes the content and choices held by this app. It does not delete original photos selected from your device. This build does not provide an app-level lock or claim encryption.',
        ),
      ],
      LegalDocument.privacy => <(String, String)>[
        (
          'Information in this app',
          'You may enter writing, moods, tags, checklists, tasks, profile details and optional photos or drawings. The app uses this content to display your journal and descriptive session statistics.',
        ),
        (
          'How information is used',
          'Search, filters, writing streaks, reflection prompts and insights operate locally on the saved entries. Insights describe saved records and are not psychological or health assessments.',
        ),
        (
          'Local journal data',
          'This CSE101 build stores content in local device storage. It uses local JSON files and preferences, with no database server and does not upload journal entries or synchronize them to the cloud. Content and preferences survive app restarts. Starting examples are inserted only when no saved journal file exists. Clearing data leaves the saved journal empty.',
        ),
        (
          'Photos and drawings',
          'Choosing a photo reads the selected file and creates a local PNG copy. Drawings are saved as editable strokes and PNG previews. The app stores these previews in its Application Documents Directory. Original selected files remain on your device and are not removed by clearing this session.',
        ),
        (
          'Third-party services',
          'This build uses Flutter and local packages for UI and file selection. It contains no AI API, advertising service, analytics integration, authentication backend or cloud storage integration. Your operating system and file provider handle their own picker and device behavior; this text does not describe those services.',
        ),
        (
          'Age and educational use',
          'This is an educational journaling demo. It has no account registration or age verification. Use it according to your school and device rules, and avoid including information you do not want in a classroom demonstration.',
        ),
        (
          'Changes to this policy',
          'Review this page when using a different release. A production version with persistence or connected services needs an updated policy reflecting its actual behavior.',
        ),
        ('Developer information', developerContact),
      ],
      LegalDocument.terms => <(String, String)>[
        (
          'Using the application',
          'These terms describe the current educational build of Mindful Journal. Use the app in a way that is appropriate for your device and classroom setting.',
        ),
        (
          'Purpose of the application',
          'Mindful Journal provides personal writing, memory exploration and optional tasks. It is not a medical service, counseling tool or professional advice.',
        ),
        (
          'Your content',
          'You choose the content you enter or import. The app does not claim ownership of your writing. Only import material you have permission to use, and be thoughtful about other people’s personal information.',
        ),
        (
          'Acceptable use',
          'Use the app lawfully and respectfully. Do not use classroom demonstrations to share content that harms others or violates their privacy.',
        ),
        (
          'Educational and demo status',
          'This CSE101 edition keeps content in local device storage. Entries, tasks, photos, drawings and settings are saved locally and remain available after restarting. Do not rely on it as the only record of important information. There is no subscription or paid service agreement in this build.',
        ),
        (
          'Availability and limitations',
          'This educational build may contain errors or interruptions. Its features and descriptive statistics should be checked before relying on them. It is provided as a demonstration, without a guarantee of uninterrupted operation or suitability for a particular purpose.',
        ),
        (
          'Changes',
          'Features and these terms may change in later releases. Before public distribution, the developer should review this text and update it to match the actual product.',
        ),
        ('Developer information', developerContact),
      ],
    };
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: JournalCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          children: [
            Text(title, style: theme.textTheme.headlineLarge),
            const SizedBox(height: 12),
            Text(
              document == LegalDocument.overview
                  ? 'Device-local storage'
                  : 'Effective date: $legalEffectiveDate',
            ),
            const SizedBox(height: 24),
            for (final section in sections) ...[
              Text(section.$1, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                section.$2,
                style: theme.textTheme.bodyLarge!.copyWith(height: 1.7),
              ),
              const SizedBox(height: 28),
            ],
          ],
        ),
      ),
    );
  }
}
