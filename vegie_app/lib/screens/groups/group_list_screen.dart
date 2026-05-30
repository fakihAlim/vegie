import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/group.dart';
import '../../providers/group_provider.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';
import 'group_detail_screen.dart';
import '../../widgets/discover_post_card.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({Key? key}) : super(key: key);

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  @override
  void initState() {
    super.initState();
    // Ambil data grup dan discover feed saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProv = Provider.of<GroupProvider>(context, listen: false);
      groupProv.fetchMyGroups();
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
          title: const Text('Komunitas Vegetarian', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Grup Saya'),
              Tab(text: 'Discover'),
            ],
          ),
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

  // TAB 1: GRUP SAYA (Pindahkan logika tampilan list grup lama Anda ke sini)
  Widget _buildMyGroupsTab() {
    return Consumer<GroupProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingGroups) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.myGroups.isEmpty) {
          return const Center(child: Text('Kamu belum bergabung dengan grup manapun.'));
        }
        return RefreshIndicator(
          onRefresh: () => provider.fetchMyGroups(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.myGroups.length,
            itemBuilder: (context, index) {
              final group = provider.myGroups[index];
              // Return widget card grup lama Anda di sini
              return ListTile(title: Text(group.name)); 
            },
          ),
        );
      },
    );
  }

  // TAB 2: DISCOVER FEED
  Widget _buildDiscoverTab() {
    return Consumer<GroupProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingDiscover) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.discoverPosts.isEmpty) {
          return const Center(child: Text('Belum ada jurnal makanan yang dibagikan.'));
        }
        return RefreshIndicator(
          onRefresh: () => provider.fetchDiscoverFeed(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
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
