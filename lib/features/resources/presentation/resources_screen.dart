import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../data/resources_repository.dart';

class ResourcesScreen extends ConsumerWidget {
  const ResourcesScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    try {
      final url = Uri.parse(urlString);
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi mở link: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(resourcesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài liệu & Link'),
      ),
      body: resourcesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (resources) {
          if (resources.isEmpty) {
            return const Center(child: Text('Chưa có tài liệu nào.'));
          }
          return ListView.separated(
            itemCount: resources.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final resource = resources[index];
              return ListTile(
                leading: const Icon(
                  Icons.link,
                  color: AppColors.accent,
                ),
                title: Text(resource.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(resource.link, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => _launchUrl(context, resource.link),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    final user = ref.read(authRepositoryProvider).currentUser;
                    if (user != null) {
                      ref.read(resourcesRepositoryProvider).deleteResource(user.uid, resource.id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Mở form thêm link mới
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
