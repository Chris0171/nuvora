import 'package:flutter/material.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';

class NoteItem extends StatefulWidget {
	const NoteItem({
		super.key,
		required this.note,
		this.onTap,
		this.onDelete,
	});

	final Note note;
	final VoidCallback? onTap;
	final VoidCallback? onDelete;

	@override
	State<NoteItem> createState() => _NoteItemState();
}

class _NoteItemState extends State<NoteItem> {
	bool _pressed = false;

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
		final contentLines = widget.note.content.length > 140 ? 4 : 3;

		return AnimatedScale(
			duration: const Duration(milliseconds: 140),
			scale: _pressed ? 0.985 : 1,
			curve: Curves.easeOutCubic,
			child: AnimatedContainer(
				duration: const Duration(milliseconds: 180),
				curve: Curves.easeOut,
				decoration: BoxDecoration(
					borderRadius: BorderRadius.circular(AppRadius.lg),
					boxShadow: [
						BoxShadow(
							color: Colors.black.withValues(alpha: _pressed ? 0.1 : 0.05),
							blurRadius: _pressed ? 18 : 9,
							offset: Offset(0, _pressed ? 10 : 5),
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
								padding: const EdgeInsets.all(AppSpacing.lg),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Row(
											crossAxisAlignment: CrossAxisAlignment.start,
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
														_formatDate(widget.note.createdAt),
														style: AppTypography.labelSmall.copyWith(
															color: AppColors.textSecondary,
														),
													),
												),
												const Spacer(),
												if (widget.note.isPinned)
													Container(
														margin: const EdgeInsets.only(right: AppSpacing.sm),
														padding: const EdgeInsets.symmetric(
															horizontal: AppSpacing.sm,
															vertical: AppSpacing.xs,
														),
														decoration: BoxDecoration(
															color: AppColors.warning.withValues(alpha: 0.18),
															borderRadius: BorderRadius.circular(AppRadius.full),
														),
														child: Row(
															mainAxisSize: MainAxisSize.min,
															children: [
																const Icon(Icons.push_pin, size: 14, color: AppColors.warning),
																const SizedBox(width: 4),
																Text(
																	'Pinned',
																	style: AppTypography.labelSmall.copyWith(
																		color: AppColors.warning,
																		fontWeight: FontWeight.w700,
																	),
																),
															],
														),
													),
												IconButton(
													onPressed: widget.onDelete,
													icon: const Icon(Icons.close),
													color: AppColors.textTertiary,
													iconSize: 20,
													padding: EdgeInsets.zero,
													constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
												),
											],
										),
										const SizedBox(height: AppSpacing.sm),
										Text(
											widget.note.title,
											style: AppTypography.headlineSmall,
											maxLines: 2,
											overflow: TextOverflow.ellipsis,
										),
										const SizedBox(height: AppSpacing.sm),
										Text(
											widget.note.content,
											style: AppTypography.bodySmall.copyWith(
												color: AppColors.textSecondary,
												height: 1.5,
											),
											maxLines: contentLines,
											overflow: TextOverflow.ellipsis,
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
