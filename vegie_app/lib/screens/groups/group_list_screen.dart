import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/group.dart';
import '../../providers/group_provider.dart';
import '../../widgets/discover_post_card.dart'; // Import widget baru
import 'create_group_screen.dart';
import 'join_group_screen.dart';
import 'group_detail_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({Key? key}) : super(key: key);

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProv = Provider.of<GroupProvider>(context, listen: false);
      groupProv.fetchGroups(); // Dibenarkan: Memanggil fetchGroups()
      groupProv.fetchDiscoverFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Komunitas', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.group_add_outlined),
              tooltip: 'Gabung Grup',
              onPressed: () => _navigateToJoin(context),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Grup Saya'),
              Tab(text: 'Discover'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'groupListFab',
          onPressed: () => _navigateToCreate(context),
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Buat Grup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        body: TabBarView(
          children: [
            _buildMyGroupsTab(),
            _buildDiscoverTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    return Consumer<GroupProvider>(
      builder: (context, provider, _) {
        // Dibenarkan: Memanggil provider.isLoading
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Dibenarkan: Memanggil provider.groups
        if (provider.groups.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchGroups(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: provider.groups.length,
            itemBuilder: (context, index) {
              return _buildGroupCard(context, provider.groups[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildDiscoverTab() {
    return Consumer<GroupProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingDiscover) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.discoverPosts.isEmpty) {
          return const Center(child: Text('Belum ada jurnal makanan yang dibagikan.', style: TextStyle(color: Colors.grey)));
        }
        return RefreshIndicator(
          onRefresh: () => provider.fetchDiscoverFeed(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: provider.discoverPosts.length,
            itemBuilder: (context, index) {
              final post = provider.discoverPosts[index];
              return DiscoverPostCard(post: post);
            },
          ),
        );
      },
    );
  }

  // --- KOMPONEN UI LAMA ANDA TETAP DIPERTAHANKAN DI BAWAH ---

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accentLight.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline, size: 64, color: AppTheme.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Grup',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Buat grup baru atau gabung ke grup yang sudah ada dengan kode undangan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _navigateToJoin(context),
                  icon: const Icon(Icons.login),
                  label: const Text('Gabung'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _navigateToCreate(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Grup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, Group group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupDetailScreen(groupId: group.id, groupName: group.name),
              ),
            ).then((_) {
              Provider.of<GroupProvider>(context, listen: false).fetchGroups();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: group.photo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(group.photo!, fit: BoxFit.cover),
                        )
                      : Center(
                          child: Text(
                            group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${group.memberCount} anggota',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: group.role == 'admin'
                                  ? Colors.amber.shade50
                                  : AppTheme.accentLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              group.role == 'admin' ? 'Admin' : 'Member',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: group.role == 'admin'
                                    ? Colors.amber.shade800
                                    : AppTheme.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    ).then((_) {
      Provider.of<GroupProvider>(context, listen: false).fetchGroups();
    });
  }

  void _navigateToJoin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
    ).then((_) {
      Provider.of<GroupProvider>(context, listen: false).fetchGroups();
    });
  }
}