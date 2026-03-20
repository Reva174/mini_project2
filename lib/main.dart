import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tournament Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

// ── Bottom Nav Shell ─────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final List<Widget> _pages = const [
    LiveScoresPage(),
    StandingsPage(),
    AdminPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Tournament Tracker'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: Colors.indigo,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_cricket), label: 'Live'),
          BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard), label: 'Standings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
    );
  }
}

// ── PAGE 1: Live Scores ──────────────────────────────────────────────────────
class LiveScoresPage extends StatelessWidget {
  const LiveScoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // FIX: removed .where() filter — show ALL matches so blank screen
      // won't happen if isLive field is missing or false
      stream: FirebaseFirestore.instance
          .collection('matches')
          .snapshots(),
      builder: (context, snapshot) {
        // Always print connection state to debug console
        debugPrint('LiveScores state: ${snapshot.connectionState}');
        debugPrint('LiveScores error: ${snapshot.error}');
        debugPrint('LiveScores docs: ${snapshot.data?.docs.length}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Show the actual error so you can debug it
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  const Text('Firestore Error:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Fix: Go to Firebase Console → Firestore → Rules\n'
                    'and set allow read, write: if true;',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // FIX: Added a seed button so data gets added with one tap
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_cricket,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No matches found in Firestore',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text(
                    'Collection "matches" is empty or missing.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _seedData,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Seed Sample Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap above to auto-add matches + teams to Firestore',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final isLive = data['isLive'] == true;
            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isLive ? Colors.red : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle,
                              color: Colors.white,
                              size: isLive ? 8 : 6),
                          const SizedBox(width: 4),
                          Text(
                            isLive ? 'LIVE' : 'ENDED',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Text(
                            data['teamA'] ?? '-',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${data['scoreA'] ?? 0}  :  ${data['scoreB'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            data['teamB'] ?? '-',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── PAGE 2: Standings ────────────────────────────────────────────────────────
class StandingsPage extends StatelessWidget {
  const StandingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .orderBy('points', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        debugPrint('Standings state: ${snapshot.connectionState}');
        debugPrint('Standings error: ${snapshot.error}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  const Text('Firestore Error:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  // FIX: orderBy requires a Firestore index — guide user
                  const Text(
                    'If error mentions "index", open the link printed\n'
                    'in your debug console to auto-create the index.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.leaderboard, size: 60, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('No teams found',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _seedData,
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Seed Sample Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: [
            Container(
              color: Colors.indigo,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: const Row(
                children: [
                  SizedBox(
                      width: 40,
                      child: Text('#',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                  Expanded(
                      child: Text('Team',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                  SizedBox(
                      width: 40,
                      child: Text('W',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                  SizedBox(
                      width: 40,
                      child: Text('L',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                  SizedBox(
                      width: 50,
                      child: Text('Pts',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data =
                      docs[i].data() as Map<String, dynamic>;
                  return Container(
                    color: i % 2 == 0
                        ? Colors.white
                        : Colors.grey.shade50,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: i < 3
                              ? Text(['🥇', '🥈', '🥉'][i],
                                  style:
                                      const TextStyle(fontSize: 18))
                              : Text('${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.grey)),
                        ),
                        Expanded(
                          child: Text(
                            data['name'] ?? '-',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: i == 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text('${data['wins'] ?? 0}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600)),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text('${data['losses'] ?? 0}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600)),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text('${data['points'] ?? 0}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                  fontSize: 16)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── PAGE 3: Admin ────────────────────────────────────────────────────────────
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Login failed. Check credentials.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _changeScore(String docId, String field, int delta) async {
    await FirebaseFirestore.instance
        .collection('matches')
        .doc(docId)
        .update({field: FieldValue.increment(delta)});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (authSnap.data == null) return _loginForm();
        return _dashboard();
      },
    );
  }

  Widget _loginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.lock_outline, size: 64, color: Colors.indigo),
          const SizedBox(height: 16),
          const Text('Admin Login',
              style:
                  TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Login',
                      style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          // FIX: show a hint so user knows what credentials to use
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Text('Create admin user in Firebase Console:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
                SizedBox(height: 4),
                Text(
                  'Authentication → Users → Add user\n'
                  'Email: admin@test.com\n'
                  'Password: admin123',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Manage Scores',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Logout',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (docs.isEmpty)
              Center(
                child: Column(
                  children: [
                    const Text('No matches yet.',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _seedData,
                      icon: const Icon(Icons.add),
                      label: const Text('Seed Sample Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '${data['teamA'] ?? '-'} vs ${data['teamB'] ?? '-'}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      // FIX: show isLive toggle feedback
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            data['isLive'] == true
                                ? Icons.circle
                                : Icons.circle_outlined,
                            color: data['isLive'] == true
                                ? Colors.red
                                : Colors.grey,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data['isLive'] == true ? 'Live' : 'Not live',
                            style: TextStyle(
                              fontSize: 12,
                              color: data['isLive'] == true
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Toggle live status
                          TextButton(
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('matches')
                                  .doc(doc.id)
                                  .update({
                                'isLive': !(data['isLive'] == true)
                              });
                            },
                            child: Text(
                              data['isLive'] == true
                                  ? 'Mark as Ended'
                                  : 'Mark as Live',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ScoreControl(
                            teamName: data['teamA'] ?? '-',
                            score: data['scoreA'] ?? 0,
                            onAdd: () =>
                                _changeScore(doc.id, 'scoreA', 1),
                            onMinus: () =>
                                _changeScore(doc.id, 'scoreA', -1),
                          ),
                          const Text('VS',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  fontSize: 18)),
                          _ScoreControl(
                            teamName: data['teamB'] ?? '-',
                            score: data['scoreB'] ?? 0,
                            onAdd: () =>
                                _changeScore(doc.id, 'scoreB', 1),
                            onMinus: () =>
                                _changeScore(doc.id, 'scoreB', -1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Reusable Score Control ────────────────────────────────────────────────────
class _ScoreControl extends StatelessWidget {
  final String teamName;
  final int score;
  final VoidCallback onAdd;
  final VoidCallback onMinus;

  const _ScoreControl({
    required this.teamName,
    required this.score,
    required this.onAdd,
    required this.onMinus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(teamName,
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 6),
        Text('$score',
            style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.indigo)),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: score > 0 ? onMinus : null,
              icon: const Icon(Icons.remove_circle_outline, size: 30),
              color: Colors.red,
            ),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle, size: 30),
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Seed Function (called from empty state buttons) ──────────────────────────
Future<void> _seedData() async {
  final db = FirebaseFirestore.instance;

  // Clear + re-add matches
  final existingMatches = await db.collection('matches').get();
  for (final doc in existingMatches.docs) {
    await doc.reference.delete();
  }

  await db.collection('matches').add({
    'teamA': 'Eagles FC',
    'teamB': 'Tigers SC',
    'scoreA': 0,
    'scoreB': 0,
    'isLive': true,
  });

  await db.collection('matches').add({
    'teamA': 'Lions FC',
    'teamB': 'Wolves SC',
    'scoreA': 2,
    'scoreB': 1,
    'isLive': false,
  });

  // Clear + re-add teams
  final existingTeams = await db.collection('teams').get();
  for (final doc in existingTeams.docs) {
    await doc.reference.delete();
  }

  final teams = [
    {'name': 'Eagles FC', 'points': 6, 'wins': 2, 'losses': 0},
    {'name': 'Tigers SC', 'points': 3, 'wins': 1, 'losses': 1},
    {'name': 'Lions FC', 'points': 3, 'wins': 1, 'losses': 1},
    {'name': 'Wolves SC', 'points': 0, 'wins': 0, 'losses': 2},
  ];

  for (final team in teams) {
    await db.collection('teams').add(team);
  }

  debugPrint('✅ Seed data added successfully');
}
