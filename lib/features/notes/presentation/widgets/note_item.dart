import 'package:flutter/material.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/core/widgets/app_icon_action_button.dart';
import 'package:nuvora/core/widgets/app_motion.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';

class NoteItem extends StatefulWidget {
	const NoteItem({
		super.key,
		required this.note,
		this.onTap,
		this.onDelete,
		this.onTogglePin,
		this.onToggleArchive,
	});

	final Note note;
	final VoidCallback? onTap;
	final VoidCallback? onDelete;
	final VoidCallback? onTogglePin;
	final VoidCallback? onToggleArchive;

	@override
	State<NoteItem> createState() => _NoteItemState();
}

class _NoteItemState extends State<NoteItem> {
	bool _pressed = false;

	String _formatDate(DateTime date) {
		final now = DateTime.now();
		final difference = now.difference(date);

		if (difference.isNegative || difference.inDays == 0) {
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
		final contentLines = widget.note.content.length > 140 ? 4 : 3;
		final dateLabel = _formatDate(widget.note.updatedAt);
		final motionDuration = AppMotion.resolvedDuration(context, AppMotion.duration);
		final shortMotionDuration = AppMotion.resolvedDuration(context, AppMotion.shortDuration);
		final motionCurve = AppMotion.resolvedCurve(context, AppMotion.curve);

		return AnimatedScale(
			duration: shortMotionDuration,
			scale: _pressed ? 0.985 : 1,
			curve: motionCurve,
			child: AnimatedContainer(
				duration: motionDuration,
				curve: motionCurve,
				decoration: BoxDecoration(
					borderRadius: BorderRadius.circular(AppRadius.lg),
					boxShadow: [
						BoxShadow(
							color: Colors.black.withValues(alpha: _pressed ? 0.08 : 0.04),
							blurRadius: _pressed ? 16 : 8,
							offset: Offset(0, _pressed ? 8 : 4),
						),
					],
				),
				child: Card(
					elevation: 0,
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(AppRadius.lg),
						side: const BorderSide(color: AppColors.border, width: 1),
					),
					child: Material(
						color: AppColors.surface,
						borderRadius: BorderRadius.circular(AppRadius.lg),
						child: InkWell(
							onTap: widget.onTap,
							onTapDown: (_) => setState(() => _pressed = true),
							onTapCancel: () => setState(() => _pressed = false),
							onTapUp: (_) => setState(() => _pressed = false),
							borderRadius: BorderRadius.circular(AppRadius.lg),
							child: Padding(
								padding: const EdgeInsets.all(AppSpacing.md),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Row(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Expanded(
													child: Text(
														widget.note.title,
														style: AppTypography.headlineMedium.copyWith(height: 1.3),
														maxLines: 2,
														overflow: TextOverflow.ellipsis,
													),
												),
												const SizedBox(width: AppSpacing.sm),
												AppIconActionButton(
													icon: widget.note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
													label: widget.note.isPinned
														? 'Unpin note ${widget.note.title}'
														: 'Pin note ${widget.note.title}',
													color: widget.note.isPinned ? AppColors.warning : AppColors.textSecondary,
													onPressed: widget.onTogglePin,
												),
												AppIconActionButton(
													icon: widget.note.archived ? Icons.unarchive_outlined : Icons.archive_outlined,
													label: widget.note.archived
														? 'Unarchive note ${widget.note.title}'
														: 'Archive note ${widget.note.title}',
													onPressed: widget.onToggleArchive,
												),
												AppIconActionButton(
													icon: Icons.close,
													label: 'Delete note ${widget.note.title}',
													onPressed: widget.onDelete,
												),
											],
										),
										const SizedBox(height: AppSpacing.md),
										Text(
											widget.note.content,
											style: AppTypography.bodyMedium.copyWith(
												color: AppColors.textSecondary,
												height: 1.45,
											),
											maxLines: contentLines,
											overflow: TextOverflow.ellipsis,
										),
										const SizedBox(height: AppSpacing.md),
										Wrap(
											spacing: AppSpacing.sm,
											runSpacing: AppSpacing.xs,
											crossAxisAlignment: WrapCrossAlignment.center,
											children: [
												Container(
													padding: const EdgeInsets.symmetric(
														horizontal: AppSpacing.sm,
														vertical: AppSpacing.xs,
													),
													decoration: BoxDecoration(
														color: AppColors.surfaceSecondary,
														borderRadius: BorderRadius.circular(AppRadius.full),
													),
													child: Text(
														dateLabel,
														style: AppTypography.labelSmall.copyWith(
															color: AppColors.textSecondary,
														),
													),
												),
												if (widget.note.archived)
													Container(
														padding: const EdgeInsets.symmetric(
															horizontal: AppSpacing.sm,
															vertical: AppSpacing.xs,
														),
														decoration: BoxDecoration(
															color: AppColors.surfaceSecondary,
															borderRadius: BorderRadius.circular(AppRadius.full),
															border: Border.all(color: AppColors.border),
														),
														child: Row(
															mainAxisSize: MainAxisSize.min,
															children: [
																const Icon(
																	Icons.archive_outlined,
																	size: 12,
																	color: AppColors.textSecondary,
																),
																const SizedBox(width: AppSpacing.xs),
																Text(
																	'Archived',
																	style: AppTypography.labelSmall.copyWith(
																		color: AppColors.textSecondary,
																	),
																),
															],
														),
													),
											],
										),
									],
								),
							),
						),
					),
				),
			),
		);
	}
}
