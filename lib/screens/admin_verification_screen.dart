// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import 'admin_member_detail_screen.dart';

class AdminVerificationScreen extends StatefulWidget {
  final String gymId;
  const AdminVerificationScreen({super.key, required this.gymId});

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen>
    with SingleTickerProviderStateMixin {
  static const _blue   = Color(0xFF00E5FF);
  static const _green  = Color(0xFF39FF14);
  static const _red    = Color(0xFFFF2D75);
  static const _amber  = Color(0xFFFFD166);
  static const _bg     = Color(0xFF05070D);
  static const _card   = Color(0xFF101827);
  static const _ink    = Color(0xFFF8FAFC);
  static const _muted  = Color(0xFF94A3B8);
  static const _subtle = Color(0xFF64748B);

  late final TabController _tabs;
  List<Map<String, dynamic>> _pending  = [];
  List<Map<String, dynamic>> _all      = [];
  StreamSubscription? _pendingSub;
  StreamSubscription? _allSub;
  String? _processingId;
  String? _processingStatus;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _pendingSub = AdminService.pendingVerificationStream(widget.gymId)
        .listen((list) {
      if (mounted) setState(() => _pending = list);
    });
    _allSub = AdminService.membersStream(widget.gymId).listen((list) {
      if (mounted) setState(() => _all = list);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pendingSub?.cancel();
    _allSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _verified =>
      _filterList(_all.where((m) => m['verificationStatus'] == 'verified').toList());
  List<Map<String, dynamic>> get _rejected =>
      _filterList(_all.where((m) => m['verificationStatus'] == 'rejected').toList());
  
  List<Map<String, dynamic>> get _filteredPending => _filterList(_pending);

  List<Map<String, dynamic>> _filterList(List<Map<String, dynamic>> list) {
    if (_searchQuery.isEmpty) return list;
    
    final query = _searchQuery.toLowerCase();
    return list.where((member) {
      final name = (member['name'] as String? ?? '').toLowerCase();
      final phone = (member['phone'] as String? ?? '').toLowerCase();
      final membership = (member['membershipType'] as String? ?? '').toLowerCase();
      final gender = (member['gender'] as String? ?? '').toLowerCase();
      
      return name.contains(query) ||
             phone.contains(query) ||
             membership.contains(query) ||
             gender.contains(query);
    }).toList();
  }

  Future<void> _setStatus(String memberId, String status) async {
    await AdminService.updateVerificationStatus(memberId, status);
  }

  Future<void> _handleAction(String memberId, String status) async {
    if (_processingId == memberId) return; // Prevent double tap
    
    setState(() {
      _processingId = memberId;
      _processingStatus = status;
    });
    
    try {
      await _setStatus(memberId, status);
      
      if (!mounted) return;
      
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Member ${status == 'verified' ? 'verified' : 'rejected'} successfully',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: status == 'verified' ? _green : _red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update status: ${e.toString()}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingId = null;
          _processingStatus = null;
        });
      }
    }
  }

  Future<void> _showBulkActions() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _subtle.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Bulk Actions',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Apply action to all ${_filteredPending.length} pending members',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              _BulkActionTile(
                icon: Icons.check_circle_outlined,
                label: 'Verify All',
                subtitle: 'Approve all pending members',
                color: _green,
                mutedColor: _muted,
                onTap: () => Navigator.pop(context, 1),
              ),
              _BulkActionTile(
                icon: Icons.block_outlined,
                label: 'Reject All',
                subtitle: 'Reject all pending members',
                color: _red,
                mutedColor: _muted,
                onTap: () => Navigator.pop(context, 2),
              ),
              _BulkActionTile(
                icon: Icons.filter_list_outlined,
                label: 'Select Multiple',
                subtitle: 'Choose specific members to act on',
                color: _blue,
                mutedColor: _muted,
                onTap: () => Navigator.pop(context, 3),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, 0),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: _bg,
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );

    if (result == 1) {
      await _bulkVerifyAll();
    } else if (result == 2) {
      await _bulkRejectAll();
    } else if (result == 3 && mounted) {
      // TODO: Implement multi-select mode
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Multi-select coming soon!'),
          backgroundColor: _blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _bulkVerifyAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        title: Text(
          'Verify All Members?',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will verify all ${_filteredPending.length} pending members. This action cannot be undone.',
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Verify All',
              style: TextStyle(color: _green, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      
      // Show processing indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Verifying all members...'),
            ],
          ),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );

      // Process all pending members
      for (final member in _filteredPending) {
        try {
          await _setStatus(member['id'] as String, 'verified');
        } catch (e) {
          // Continue with others even if one fails
        }
      }

      if (!mounted) return;
      
      // Show completion message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verified ${_filteredPending.length} members',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _bulkRejectAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        title: Text(
          'Reject All Members?',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will reject all ${_filteredPending.length} pending members. This action cannot be undone.',
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Reject All',
              style: TextStyle(color: _red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      
      // Show processing indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Rejecting all members...'),
            ],
          ),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );

      // Process all pending members
      for (final member in _filteredPending) {
        try {
          await _setStatus(member['id'] as String, 'rejected');
        } catch (e) {
          // Continue with others even if one fails
        }
      }

      if (!mounted) return;
      
      // Show completion message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rejected ${_filteredPending.length} members',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        title: Text('Member Verification (${_pending.length} pending)',
            style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _subtle.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search_outlined, color: _subtle, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by name, phone, or membership...',
                            hintStyle: TextStyle(color: _subtle, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(color: _ink, fontSize: 13),
                          cursorColor: _blue,
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear_outlined, color: _subtle, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40),
                        ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabs,
                labelColor: _blue,
                unselectedLabelColor: _muted,
                indicatorColor: _blue,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: [
                  Tab(
                    icon: _pending.isEmpty 
                      ? const Icon(Icons.pending_outlined, size: 18)
                      : Badge(
                          smallSize: 6,
                          backgroundColor: _amber,
                          child: const Icon(Icons.pending_outlined, size: 18),
                        ),
                    text: 'Pending (${_filteredPending.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    text: 'Verified (${_verified.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.block_outlined, size: 18),
                    text: 'Rejected (${_rejected.length})',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _memberList(_filteredPending, showActions: true),
          _memberList(_verified, showActions: false),
          _memberList(_rejected, showActions: false),
        ],
      ),
      floatingActionButton: _tabs.index == 0 && _filteredPending.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBulkActions,
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(Icons.verified_outlined, size: 20),
              label: const Text('Bulk Actions', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _memberList(List<Map<String, dynamic>> members,
      {required bool showActions}) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _bg,
                shape: BoxShape.circle,
                border: Border.all(color: _subtle.withOpacity(0.2), width: 1.5),
              ),
              child: Icon(
                _searchQuery.isNotEmpty ? Icons.search_off_outlined :
                  (showActions ? Icons.pending_actions_outlined : 
                    (members == _verified ? Icons.verified_outlined : Icons.block_outlined)),
                color: _subtle.withOpacity(0.5),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty ? 'No Search Results' :
                (showActions ? 'No Pending Verifications' : 
                  (members == _verified ? 'No Verified Members' : 'No Rejected Members')),
              style: TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty ? 'No members match "$_searchQuery"' :
                (showActions ? 'All members have been reviewed' : 
                  'Check back later for updates'),
              style: TextStyle(
                color: _muted,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (showActions && _searchQuery.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _blue.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_outlined, color: _blue, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Pull down to refresh',
                      style: TextStyle(color: _blue, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            if (_searchQuery.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _blue.withOpacity(0.2)),
                ),
                child: GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear_outlined, color: _blue, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Clear search',
                        style: TextStyle(color: _blue, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        // Trigger refresh of data
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {});
      },
      color: _blue,
      backgroundColor: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        separatorBuilder: (_, i) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _memberTile(members[i], showActions: showActions),
      ),
    );
  }

  Widget _memberTile(Map<String, dynamic> m, {required bool showActions}) {
    final name       = m['name']           as String? ?? '—';
    final phone      = m['phone']          as String? ?? '—';
    final membership = m['membershipType'] as String? ?? 'Basic';
    final gender     = m['gender']         as String? ?? '—';
    final vs         = m['verificationStatus'] as String? ?? 'pending';

    final membershipColors = {
      'Basic':   _blue,
      'Premium': _amber,
      'VIP':     const Color(0xFFB967FF),
    };
    final mColor = membershipColors[membership] ?? _blue;

    final vsColor = vs == 'verified' ? _green
        : vs == 'rejected' ? _red : _amber;

    // Parse join date
    String joinedStr = '—';
    try {
      final raw = m['createdAt'];
      if (raw != null) {
        final dt = raw is DateTime ? raw
            : DateTime.tryParse(raw.toString());
        if (dt != null) joinedStr = DateFormat('MMM d, yyyy').format(dt);
      }
    } catch (_) {}

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => AdminMemberDetailScreen(
          memberId: m['id'] as String, gymId: widget.gymId,
        ),
      )),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: vs == 'pending'
              ? Border.all(color: _amber.withOpacity(0.3), width: 1.5)
              : vs == 'verified'
                ? Border.all(color: _green.withOpacity(0.2), width: 1)
                : vs == 'rejected'
                  ? Border.all(color: _red.withOpacity(0.2), width: 1)
                  : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(vs == 'pending' ? 0.06 : 0.04),
              blurRadius: vs == 'pending' ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        mColor.withOpacity(0.15),
                        mColor.withOpacity(0.25),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: mColor.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: mColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: mColor.withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  mColor.withOpacity(0.1),
                                  mColor.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: mColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              membership,
                              style: TextStyle(
                                color: mColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phone,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip(Icons.person_outline, gender),
                const SizedBox(width: 10),
                _infoChip(Icons.calendar_today_outlined, 'Joined $joinedStr'),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        vsColor.withOpacity(0.1),
                        vsColor.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: vsColor.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: vsColor.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vs == 'verified'
                            ? Icons.verified_outlined
                            : vs == 'rejected'
                                ? Icons.block_outlined
                                : Icons.pending_outlined,
                        color: vsColor,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vs[0].toUpperCase() + vs.substring(1),
                        style: TextStyle(
                          color: vsColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showActions) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Verify',
                      icon: Icons.check_circle_outlined,
                      color: _green,
                      isLoading: _processingId == m['id'] && _processingStatus == 'verified',
                      onTap: () => _handleAction(m['id'] as String, 'verified'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: 'Reject',
                      icon: Icons.cancel_outlined,
                      color: _red,
                      isLoading: _processingId == m['id'] && _processingStatus == 'rejected',
                      onTap: () => _handleAction(m['id'] as String, 'rejected'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _subtle, size: 12),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: _muted, fontSize: 11)),
      ],
    );
  }
}

class _BulkActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color mutedColor;
  final VoidCallback onTap;

  const _BulkActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_outlined,
                  color: color.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(isLoading ? 0.15 : 0.1),
              color.withOpacity(isLoading ? 0.25 : 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(isLoading ? 0.4 : 0.3),
            width: isLoading ? 1.5 : 1,
          ),
          boxShadow: [
            if (!isLoading)
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
