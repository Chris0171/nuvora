import 'package:flutter/material.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';

class NoteItem extends StatelessWidget {
	const NoteItem({
		super.key,
		required this.note,
		this.onTap,
		this.onDelete,
	});

	final Note note;
	final VoidCallback? onTap;
	final VoidCallback? onDelete;

	String _formatDate(DateTime date) {
		final now = DateTime.now();
		final difference = now.difference(date);

		if (difference.inDays == 0) {
			return 'Today';
		} else if (difference.inDays == 1) {
			return 'Yesterday';
		} else if (difference.inDays < 7) {
			return '${difference.inDays} days ago';
		} else if (difference.inDays < 30) {
			final weeks = (difference.inDays / 7).floor();
			return '$weeks week${weeks > 1 ? 's' : ''} ago';
		} else {
			return '${date.month}/${date.day}/${date.year}';
		}
	}

	@override
	Widget build(BuildContext context) {
		return Card(
			elevation: AppElevation.xs,
			shape: RoundedRectangleBorder(
				borderRadius: BorderRadius.circular(AppRadius.lg),
				side: const BorderSide(color: AppColors.border, width: 1),
			),
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(AppRadius.lg),
				child: Padding(
					padding: const EdgeInsets.all(AppSpacing.lg),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							// Header row with title and menu
							Row(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									// Icon
									Padding(
										padding: const EdgeInsets.only(right: AppSpacing.md, top: AppSpacing.xs),
										child: Container(
											width: 36,
											height: 36,
											decoration: BoxDecoration(
												color: AppColors.primaryLight,
												borderRadius: BorderRadius.circular(AppRadius.md),
											),
											child: const Icon(
												Icons.note_outlined,
												size: 20,
												color: AppColors.primary,
											),
										),
									),
									// Title
									Expanded(
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Text(
													note.title,
													style: AppTypography.bodyLarge,
													maxLines: 2,
													overflow: TextOverflow.ellipsis,
												),
												const SizedBox(height: AppSpacing.xs),
												Text(
													_formatDate(note.createdAt),
													style: AppTypography.labelSmall.copyWith(
														color: AppColors.textTertiary,
													),
												),
											],
										),
									),
									// Delete button
									IconButton(
										onPressed: onDelete,
										icon: const Icon(Icons.close),
										color: AppColors.textTertiary,
										iconSize: 20,
										padding: EdgeInsets.zero,
										constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
									),
								],
							),
							const SizedBox(height: AppSpacing.md),
							// Content preview
							Text(
								note.content,
								style: AppTypography.bodySmall.copyWith(
									color: AppColors.textSecondary,
									height: 1.5,
								),
								maxLines: 3,
								overflow: TextOverflow.ellipsis,
							),
						],
					),
				),
			),
		);
	}
}
