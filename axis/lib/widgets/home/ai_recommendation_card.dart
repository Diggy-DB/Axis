import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';
import '../../core/constants/app_constants.dart';

class AIRecommendationCard extends StatelessWidget {
  const AIRecommendationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AIProvider>(
      builder: (context, aiProvider, child) {
        if (aiProvider.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final recommendation = aiProvider.todayRecommendation;
        if (recommendation == null) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'AI Recommendation',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (recommendation.insights.isNotEmpty)
                  ...recommendation.insights.take(2).map((insight) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡 '),
                            Expanded(child: Text(insight)),
                          ],
                        ),
                      )),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Suggested task limit: ${recommendation.suggestedTaskLimit}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
