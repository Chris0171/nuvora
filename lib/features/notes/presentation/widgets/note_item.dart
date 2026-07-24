import 'package:flutter/material.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/core/widgets/app_motion.dart';
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
		final dateLabel = _formatDate(widget.note.createdAt);

		return AnimatedScale(
			duration: AppMotion.shortDuration,
			scale: _pressed ? 0.985 : 1,
			curve: AppMotion.curve,
			child: AnimatedContainer(
				duration: AppMotion.duration,
				curve: AppMotion.curve,
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
												if (widget.note.isPinned)
													AnimatedOpacity(
														duration: AppMotion.shortDuration,
														opacity: 1,
														child: Container(
															margin: const EdgeInsets.only(right: AppSpacing.xs),
															padding: const EdgeInsets.all(AppSpacing.xs),
															decoration: BoxDecoration(
																color: AppColors.surfaceSecondary,
																borderRadius: BorderRadius.circular(AppRadius.full),
															),
															child: const Icon(
																Icons.push_pin,
																size: 14,
																color: AppColors.textSecondary,
															),
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
