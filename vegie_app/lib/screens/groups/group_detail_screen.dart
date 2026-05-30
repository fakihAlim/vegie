import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/group.dart';
import '../../models/group_post.dart';
import '../../providers/group_provider.dart';
import '../../services/group_service.dart';
import '../../services/activity_log_service.dart';
import '../../widgets/group_post_card.dart';

class GroupDetailScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const GroupDetailScreen({Key? key, required this.groupId, required this.groupName}) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GroupService _groupService = GroupService();

  Group? _group;
  List<GroupPost> _posts = [];
  List<GroupMember> _members = [];
  bool _isLoadingGroup = true;
  bool _isLoadingPosts = true;
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    ActivityLogService.instance.logEvent('group_view', extraData: {
      'group_id': widget.groupId,
      'group_name': widget.groupName,
    });
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadGroup();
    _loadPosts();
    _loadMembers();
  }

  Future<void> _loadGroup() async {
    final detail = await _groupService.getGroupDetail(widget.groupId);
    if (mounted) setState(() { _group = detail; _isLoadingGroup = false; });
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoadingPosts = true);
    final posts = await _groupService.getPosts(widget.groupId);
    if (mounted) setState(() { _posts = posts; _isLoadingPosts = false; });
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoadingMembers = true);
    final members = await _groupService.getMembers(widget.groupId);
    if (mounted) setState(() { _members = members; _isLoadingMembers = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryDark,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
                    ),
                  ),
                  child: SafeArea(
                    child: _isLoadingGroup
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _group?.name ?? widget.groupName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.people, size: 16, color: Colors.white70),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_group?.memberCount ?? 0} anggota',
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                    const SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: () {
                                        if (_group != null) {
                                          Clipboard.setData(ClipboardData(text: _group!.code));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Kode undangan disalin!'), duration: Duration(seconds: 1)),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.copy, size: 14, color: Colors.white),
                                            const SizedBox(width: 4),
                                            Text(
                                              _group?.code ?? '...',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                          ],
                                        ),
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
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'leave') _confirmLeave();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'leave', child: Text('Keluar dari Grup')),
                  ],
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: 'Postingan'),
                  Tab(text: 'Anggota'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(),
            _buildMembersTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  // ── Posts Tab ──
  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: AppTheme.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('Belum ada postingan', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Jadilah yang pertama berbagi! 🌱', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: _posts.length,
        itemBuilder: (_, i) => GroupPostCard(post: _posts[i]),
      ),
    );
  }

  // ── Members Tab ──
  Widget _buildMembersTab() {
    if (_isLoadingMembers) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: _members.length,
        itemBuilder: (_, i) => _buildMemberTile(_members[i]),
      ),
    );
  }

  Widget _buildMemberTile(GroupMember member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.accentLight,
            backgroundImage: member.photo != null ? NetworkImage(member.photo!) : null,
            child: member.photo == null
                ? Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark, fontSize: 18),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                if (member.bio != null && member.bio!.isNotEmpty)
                  Text(member.bio!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: member.role == 'admin' ? Colors.amber.shade50 : AppTheme.accentLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              member.role == 'admin' ? 'Admin' : 'Member',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: member.role == 'admin' ? Colors.amber.shade800 : AppTheme.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Create Post Dialog ──
  void _showCreatePostDialog() {
    final contentController = TextEditingController();
    String selectedType = 'text';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx2).viewInsets.bottom + 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Buat Postingan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Type selector
                  Row(
                    children: [
                      _buildTypeChip('text', 'Diskusi', Icons.chat_bubble_outline, selectedType, (v) => setModalState(() => selectedType = v)),
                      const SizedBox(width: 8),
                      _buildTypeChip('achievement', 'Pencapaian', Icons.emoji_events_outlined, selectedType, (v) => setModalState(() => selectedType = v)),
                      const SizedBox(width: 8),
                      _buildTypeChip('quote', 'Kutipan', Icons.format_quote, selectedType, (v) => setModalState(() => selectedType = v)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: contentController,
                    decoration: const InputDecoration(hintText: 'Apa yang ingin Anda bagikan?'),
                    maxLines: 4,
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      if (contentController.text.trim().isEmpty) return;
                      Navigator.pop(ctx2);
                      final response = await _groupService.createPost(widget.groupId, contentController.text.trim(), selectedType);
                      if (response['success'] == true) {
                        _loadPosts();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Postingan berhasil dibuat!'), backgroundColor: AppTheme.success),
                          );
                        }
                      }
                    },
                    child: const Text('Kirim'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon, String selected, Function(String) onSelect) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ── Leave Group ──
  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Grup?'),
        content: const Text('Anda yakin ingin meninggalkan grup ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await Provider.of<GroupProvider>(context, listen: false).leaveGroup(widget.groupId);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Anda telah keluar dari grup'), backgroundColor: AppTheme.success),
                );
              }
            },
            child: const Text('Keluar', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
