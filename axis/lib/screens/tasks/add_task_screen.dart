import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../models/category.dart' as models;
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/constants/enums.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  TaskPriority priority = TaskPriority.medium;
  String? selectedCategory;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _showCategoryManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CategoryManagementSheet(
        onCategorySelected: (category) {
          setState(() {
            selectedCategory = category.label;
          });
        },
      ),
    );
  }

  String _priorityName(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  Future<void> _saveTask() async {
    if (titleController.text.trim().isEmpty) return;

    DateTime? scheduledDateTime;
    if (selectedDate != null) {
      if (selectedTime != null) {
        scheduledDateTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          selectedTime!.hour,
          selectedTime!.minute,
        );
      } else {
        // If only date is selected, use midnight
        scheduledDateTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
        );
      }
    }

    final task = Task(
      id: '',
      title: titleController.text.trim(),
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      scheduledDate: scheduledDateTime,
      dueDate: selectedDate,
      status: TaskStatus.pending,
      priority: priority,
      category: selectedCategory,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await Provider.of<TaskProvider>(context, listen: false)
        .createTask(task);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create task')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    selectedDate = date;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 24),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deadline Date',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedDate != null
                              ? DateFormat('MMM d, y').format(selectedDate!)
                              : 'Not set',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: selectedTime ?? TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    selectedTime = time;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 24),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deadline Time',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedTime != null
                              ? selectedTime!.format(context)
                              : 'Not set',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showCategoryManagement,
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('Manage'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.label, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                DropdownButton<String?>(
                                  value: selectedCategory,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedCategory = value;
                                    });
                                  },
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('No category'),
                                    ),
                                    ...categoryProvider.categories.map(
                                      (category) => DropdownMenuItem<String?>(
                                        value: category.label,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color:
                                                    Color(category.colorValue),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(category.label),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Priority',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        DropdownButton<TaskPriority>(
                          value: priority,
                          isExpanded: true,
                          underline: const SizedBox(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                priority = value;
                              });
                            }
                          },
                          items: [
                            TaskPriority.low,
                            TaskPriority.medium,
                            TaskPriority.high
                          ]
                              .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(_priorityName(p)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryManagementSheet extends StatefulWidget {
  final Function(models.Category) onCategorySelected;

  const _CategoryManagementSheet({
    required this.onCategorySelected,
  });

  @override
  State<_CategoryManagementSheet> createState() =>
      _CategoryManagementSheetState();
}

class _CategoryManagementSheetState extends State<_CategoryManagementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  Color _selectedColor = Colors.blue;
  models.Category? _editingCategory;

  final List<Color> _availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
  ];

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _startEditing(models.Category category) {
    setState(() {
      _editingCategory = category;
      _labelController.text = category.label;
      _selectedColor = Color(category.colorValue);
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingCategory = null;
      _labelController.clear();
      _selectedColor = Colors.blue;
    });
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);

    if (_editingCategory != null) {
      // Update existing category
      final updatedCategory = models.Category(
        id: _editingCategory!.id,
        label: _labelController.text.trim(),
        colorValue: _selectedColor.toARGB32(),
        createdAt: _editingCategory!.createdAt,
      );
      await categoryProvider.updateCategory(updatedCategory);
    } else {
      // Create new category
      await categoryProvider.createCategory(
        _labelController.text.trim(),
        _selectedColor.toARGB32(),
      );
    }

    _cancelEditing();
  }

  Future<void> _deleteCategory(models.Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<CategoryProvider>(context, listen: false)
          .deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Manage Categories',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _labelController,
                        decoration: InputDecoration(
                          labelText: _editingCategory != null
                              ? 'Edit Category Name'
                              : 'New Category Name',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a category name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Color',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _availableColors.map((color) {
                          final isSelected =
                              color.toARGB32() == _selectedColor.toARGB32();
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: _saveCategory,
                              child: Text(
                                _editingCategory != null
                                    ? 'Update Category'
                                    : 'Add Category',
                              ),
                            ),
                          ),
                          if (_editingCategory != null) ...[
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: _cancelEditing,
                              child: const Text('Cancel'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Existing Categories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Consumer<CategoryProvider>(
                    builder: (context, categoryProvider, child) {
                      if (categoryProvider.categories.isEmpty) {
                        return const Center(
                          child: Text('No categories yet'),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: categoryProvider.categories.length,
                        itemBuilder: (context, index) {
                          final category = categoryProvider.categories[index];
                          return Card(
                            child: ListTile(
                              leading: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Color(category.colorValue),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(category.label),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _startEditing(category),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _deleteCategory(category),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
