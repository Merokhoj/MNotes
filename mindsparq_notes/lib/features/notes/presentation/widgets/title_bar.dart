import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/neo_glass.dart';

class TitleBarWidget extends StatelessWidget {
  final VoidCallback onNewNote;
  final VoidCallback? onImportNote;
  final bool isSidebarCollapsed;
  final bool isNotesListCollapsed;
  final VoidCallback onToggleSidebar;
  final VoidCallback onToggleNotesList;

  const TitleBarWidget({
    super.key,
    required this.onNewNote,
    this.onImportNote,
    required this.isSidebarCollapsed,
    required this.isNotesListCollapsed,
    required this.onToggleSidebar,
    required this.onToggleNotesList,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.sidebarBackground,
        border: Border(bottom: BorderSide(color: colors.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          // Sidebar Toggle Button
          Tooltip(
            message: isSidebarCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
            child: InkWell(
              onTap: onToggleSidebar,
              child: SizedBox(
                width: isSidebarCollapsed ? AppSpacing.sidebarCollapsedWidth : AppSpacing.sidebarWidth,
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.md),
                    Icon(
                      isSidebarCollapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
                      color: colors.textSecondary,
                      size: 19,
                    ),
                    if (!isSidebarCollapsed) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill), color: colors.primary, size: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'MindSparQ',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, color: colors.border.withOpacity(0.5)),

          // Notes List Toggle Button
          Tooltip(
            message: isNotesListCollapsed ? 'Show Notes List' : 'Hide Notes List',
            child: InkWell(
              onTap: onToggleNotesList,
              child: Container(
                width: 38,
                alignment: Alignment.center,
                child: Icon(
                  isNotesListCollapsed ? Icons.list_rounded : Icons.view_sidebar_rounded,
                  color: isNotesListCollapsed ? colors.primary : colors.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ),
          Container(width: 1, color: colors.border.withOpacity(0.5)),

          // Middle window space
          const Expanded(child: SizedBox()),

          // Import Note Button
          if (onImportNote != null) ...[
            NeoGlassButton(
              onPressed: onImportNote!,
              tooltip: 'Import Markdown note (Ctrl+O)',
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.file_upload_outlined, size: 14, color: colors.textPrimary),
                  const SizedBox(width: 4),
                  const Text('Import', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],

          // New Note Button (Primary Neo-Glass button with subtle prism glow)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: NeoGlassButton(
              onPressed: onNewNote,
              isPrimary: true,
              tooltip: 'Create a new note (Ctrl+N)',
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 15, color: Colors.white),
                  SizedBox(width: 4),
                  Text('New Note', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
