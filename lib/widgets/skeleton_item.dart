import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonItem extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonItem({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class EarthquakeListSkeleton extends StatelessWidget {
  const EarthquakeListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const SkeletonItem(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.all(Radius.circular(25)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonItem(width: double.infinity, height: 16),
                    const SizedBox(height: 8),
                    SkeletonItem(width: MediaQuery.of(context).size.width * 0.4, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const SkeletonItem(width: 40, height: 14),
            ],
          ),
        );
      },
    );
  }
}

class EarthquakeDetailSkeleton extends StatelessWidget {
  const EarthquakeDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonItem(width: double.infinity, height: 32),
          const SizedBox(height: 16),
          const SkeletonItem(width: 200, height: 16),
          const SizedBox(height: 12),
          const SkeletonItem(width: 250, height: 16),
          const SizedBox(height: 12),
          const SkeletonItem(width: 180, height: 16),
          const SizedBox(height: 12),
          const SkeletonItem(width: 150, height: 16),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) => 
              const SkeletonItem(width: 100, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
            ),
          ),
        ],
      ),
    );
  }
}
