import 'package:flutter/material.dart';

class Item {
  Item(this.name);

  String name;
  bool bought = false;
  int quantity = 1;
  String note = '';
  String category = 'Food';
}

void main() {
  runApp(const ShoppingApp());
}

class ShoppingApp extends StatelessWidget {
  const ShoppingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.orange),
      home: const HomeScreen(title: 'Shopping List'),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final items = [Item('Milk'), Item('Bread'), Item('Rice')];
  final controller = TextEditingController();
  String filter = 'All';

  void showMessage(String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), action: action),
    );
  }

  void addItem() {
    final text = controller.text.trim();
    if (text.isEmpty) {
      showMessage('Type an item first');
      return;
    }
    final key = text.toLowerCase();
    for (final item in items) {
      if (item.name.trim().toLowerCase() == key) {
        setState(() {
          item.quantity++;
        });
        showMessage('${item.name} is already on the list: now ×${item.quantity}');
        controller.clear();
        return;
      }
    }
    setState(() {
      items.add(Item(text));
    });
    controller.clear();
  }

  void deleteItem(Item item) {
    final index = items.indexOf(item);
    setState(() {
      items.removeAt(index);
    });
    showMessage(
      '${item.name} removed',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          setState(() {
            items.insert(index, item);
          });
        },
      ),
    );
  }

  List<Item> visibleItems() {
    if (filter == 'To buy') {
      return items.where((item) => !item.bought).toList();
    }
    if (filter == 'Bought') {
      return items.where((item) => item.bought).toList();
    }
    return [
      ...items.where((item) => !item.bought),
      ...items.where((item) => item.bought),
    ];
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = items.where((item) => !item.bought).length;
    final visible = visibleItems();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} ($left left)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: () {
              setState(() {
                items.removeWhere((item) => item.bought);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'Add an item'),
                    onSubmitted: (_) => addItem(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: addItem,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final label in ['All', 'To buy', 'Bought']) ...[
                  ChoiceChip(
                    label: Text(label),
                    selected: filter == label,
                    onSelected: (_) {
                      setState(() {
                        filter = label;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Your list is empty'))
                : visible.isEmpty
                ? const Center(child: Text('Nothing here'))
                : ListView.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final item = visible[index];
                final subtitle = item.note.isEmpty
                    ? item.category
                    : '${item.category} · ${item.note}';
                return ListTile(
                  leading: Icon(
                    item.bought
                        ? Icons.check_circle
                        : Icons.shopping_basket,
                  ),
                  title: Text(
                    item.name,
                    style: TextStyle(
                      decoration: item.bought
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Text(subtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (item.quantity == 1) return;
                          setState(() => item.quantity--);
                        },
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() => item.quantity++);
                        },
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => deleteItem(item),
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() => item.bought = !item.bought);
                  },
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailsScreen(item: item),
                      ),
                    ).then((_) {
                      setState(() {});
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.item});

  final Item item;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late final TextEditingController nameController;
  late final TextEditingController noteController;
  late String category;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.name);
    noteController = TextEditingController(text: widget.item.note);
    category = widget.item.category;
  }

  @override
  void dispose() {
    nameController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void save() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type a name')),
      );
      return;
    }
    widget.item.name = name;
    widget.item.note = noteController.text.trim();
    widget.item.category = category;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'the 1 litre bottle',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final label in ['Food', 'Drinks', 'Home'])
                ChoiceChip(
                  label: Text(label),
                  selected: category == label,
                  onSelected: (_) {
                    setState(() => category = label);
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}