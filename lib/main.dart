import 'package:flutter/material.dart';
import 'package:flutter_product_image/login.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login.dart';

// ตรวจสอบให้แน่ใจว่าชื่อไฟล์และชื่อ Class ในไฟล์เหล่านี้ถูกต้อง
import 'add_product_page.dart';
import 'edit_product_page.dart';

void main() => runApp(const MyApp());

//////////////////////////////////////////////////////////////
// ✅ CONFIG
//////////////////////////////////////////////////////////////

const String baseUrl = "http://127.0.0.1/Student/php_api/";

//////////////////////////////////////////////////////////////
// ✅ APP ROOT
//////////////////////////////////////////////////////////////

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // เปลี่ยนจาก userList() เป็น UserList()
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

//////////////////////////////////////////////////////////////
// ✅ USER LIST PAGE
//////////////////////////////////////////////////////////////

class UserList extends StatefulWidget {
  final String name;
  const UserList({super.key,required this.name});
  

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  List users = [];
  List filteredUsers = []; // ปรับเป็น camelCase

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // ✅ FETCH DATA
  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse("${baseUrl}show_data.php"));

      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body);
          filteredUsers = users;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
  }

  // ✅ SEARCH
  void filterUsers(String query) {
    setState(() {
      filteredUsers = users.where((user) {
        final name = user['name']?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  // ✅ DELETE
  Future<void> deleteUser(int id) async {
    try {
      final response = await http.get(
        Uri.parse("${baseUrl}delete_product.php?id=$id"),
      );

      final data = json.decode(response.body);

      if (data["success"] == true) {
        fetchUsers();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("ลบข้อมูลเรียบร้อย")));
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  // ✅ CONFIRM DELETE
  void confirmDelete(dynamic user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: Text("ต้องการลบ ${user['name']} ?"),
        actions: [
          TextButton(
            child: const Text("ยกเลิก"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("ลบ", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              deleteUser(int.parse(user['id'].toString()));
            },
          ),
        ],
      ),
    );
  }

  // ✅ OPEN EDIT PAGE
  void openEdit(dynamic user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EdituserPage(
          user: user,
        ), // ตรวจสอบว่าในไฟล์ EditProductPage รับค่าชื่อ users จริงหรือไม่
      ),
    ).then((value) => fetchUsers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('student List'),
      actions: [
         Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text("Welcome ${widget.name}"),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
                (route) => false,
              );

            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search user',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: filterUsers,
            ),
          ),

          // 📦 LIST
          Expanded(
            child: filteredUsers.isEmpty && searchController.text.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      String imageUrl = "${baseUrl}images/${user['image']}";

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.person),
                              ),
                            ),
                          ),
                          title: Text(user['name'] ?? 'No Name'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("email: ${user['email'] ?? '-'}"),
                      
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                openEdit(user);
                              } else if (value == 'delete') {
                                confirmDelete(user);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('แก้ไข'),
                              ),
                              PopupMenuItem(value: 'delete', child: Text('ลบ')),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserDetail(user: user),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // ตรวจสอบชื่อ Class ในไฟล์ add_product_page.dart ว่าชื่อ AddProductPage หรือไม่
              builder: (_) => const AddusersPage(),
            ),
          ).then((value) => fetchUsers());
        },
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
// ✅ USER DETAIL PAGE
//////////////////////////////////////////////////////////////

class UserDetail extends StatelessWidget {
  final dynamic user;
  const UserDetail({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    String imageUrl = "${baseUrl}images/${user['image']}";

    return Scaffold(
      appBar: AppBar(title: Text(user['name'] ?? 'Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported, size: 100),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "ชื่อ: ${user['name'] ?? '-'}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text(
              "เบอร์โทรศัพท์: ${user['phone'] ?? '-'}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "อีเมล: ${user['email'] ?? '-'}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
          
            
          ],
        ),
      ),
    );
  }
}
