import 'package:flutter/material.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';

class TaskItem extends StatelessWidget {
	const TaskItem({
		super.key,
		required this.task,
		this.onTap,
		this.onDelete,
		this.onToggleCompleted,
	});

	final Task task;
	final VoidCallback? onTap;
	final VoidCallback? onDelete;
	final ValueChanged<bool>? onToggleCompleted;

	Color _getPriorityColor() {
		switch (task.priority) {
			case Priority.low:
				return AppColors.priorityLow;
			case Priority.medium:
				return AppColors.priorityMedium;
			case Priority.high:
				return AppColors.priorityHigh;
			case Priority.urgent:
				return AppColors.priorityUrgent;
		}
	}

	String _getPriorityLabel() {
		return task.priority.name.toUpperCase();
	}

	String? _formatDueDate() {
		if (task.dueDate == null) return null;
		final now = DateTime.now();
		final date = task.dueDate!;
		
		if (date.year == now.year &&
				date.month == now.month &&
				date.day == now.day) {
			return 'Today';
		}
		
		if (date.year == now.year &&
				date.month == now.month &&
				date.day == now.day + 1) {
			return 'Tomorrow';
		}
		
		return '${date.month}/${date.day}/${date.year}';
	}

	@override
	Widget build(BuildContext context) {
		final dueDate = _formatDueDate();
		final isDue = task.dueDate != null && 
			task.dueDate!.isBefore(DateTime.now()) && 
			!task.isCompleted;

		return Card(
			elevation: AppElevation.xs,
			shape: RoundedRectangleBorder(
				borderRadius: BorderRadius.circular(AppRadius.lg),
				side: BorderSide(
					color: isDue ? AppColors.danger.withValues(alpha: 0.2) : AppColors.border,
					width: 1,
				),
			),
			child: Container(
				decoration: BoxDecoration(
					borderRadius: BorderRadius.circular(AppRadius.lg),
					color: task.isCompleted 
						? AppColors.surfaceSecondary 
						: AppColors.surface,
				),
				child: InkWell(
					onTap: onTap,
					borderRadius: BorderRadius.circular(AppRadius.lg),
					child: Padding(
						padding: const EdgeInsets.all(AppSpacing.lg),
						child: Row(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								// Checkbox
								Padding(
									padding: const EdgeInsets.only(top: AppSpacing.xs, right: AppSpacing.lg),
									child: SizedBox(
										width: 24,
										height: 24,
										child: Checkbox(
											value: task.isCompleted,
											onChanged: (value) {
												if (value == null) return;
												onToggleCompleted?.call(value);
											},
										),
									),
								),
								// Content
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											// Title
											Text(
												task.title,
												style: AppTypography.bodyLarge.copyWith(
													decoration: task.isCompleted 
														? TextDecoration.lineThrough 
														: null,
													color: task.isCompleted 
														? AppColors.textTertiary 
														: AppColors.textPrimary,
												),
												maxLines: 2,
												overflow: TextOverflow.ellipsis,
											),
											// Description
											if (task.description != null) ...[
												const SizedBox(height: AppSpacing.sm),
												Text(
													task.description!,
													style: AppTypography.bodySmall.copyWith(
														color: task.isCompleted 
															? AppColors.textTertiary 
															: AppColors.textSecondary,
													),
													maxLines: 2,
													overflow: TextOverflow.ellipsis,
												),
											],
											// Priority and Due Date
											if (task.priority != Priority.medium || dueDate != null) ...[
												const SizedBox(height: AppSpacing.md),
												Row(
													children: [
														// Priority Badge
														Container(
															padding: const EdgeInsets.symmetric(
																horizontal: AppSpacing.sm,
																vertical: AppSpacing.xs,
															),
															decoration: BoxDecoration(
																color: _getPriorityColor().withValues(alpha: 0.1),
																borderRadius: BorderRadius.circular(AppRadius.sm),
															),
															child: Text(
																_getPriorityLabel(),
																style: AppTypography.labelSmall.copyWith(
																	color: _getPriorityColor(),
																	fontWeight: FontWeight.w700,
																),
															),
														),
														const SizedBox(width: AppSpacing.md),
														// Due Date
														if (dueDate != null)
															Row(
																children: [
																	Icon(
																		Icons.calendar_today,
																		size: 14,
																		color: isDue 
																			? AppColors.danger 
																			: AppColors.textSecondary,
																	),
																	const SizedBox(width: AppSpacing.xs),
																	Text(
																		dueDate,
																		style: AppTypography.labelSmall.copyWith(
																			color: isDue 
																				? AppColors.danger 
																				: AppColors.textSecondary,
																		),
																	),
																],
															),
													],
												),
											],
										],
									),
								),
								// Delete Button
								Padding(
									padding: const EdgeInsets.only(left: AppSpacing.md),
									child: IconButton(
										onPressed: onDelete,
										icon: const Icon(Icons.close),
										color: AppColors.textTertiary,
										iconSize: 20,
										padding: EdgeInsets.zero,
										constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
									),
								),
							],
						),
					),
				),
			),
		);
	}
}
