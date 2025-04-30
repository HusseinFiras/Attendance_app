import 'package:flutter/material.dart';

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المقاتلين',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      // TODO: Implement add employee functionality
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة مقاتل'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      // TODO: Implement export functionality
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('تصدير'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      // TODO: Implement import functionality
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('استيراد'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search and Filter Bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: 'فعال',
                    items: const [
                      DropdownMenuItem(
                        value: 'فعال',
                        child: Text('فعال'),
                      ),
                      DropdownMenuItem(
                        value: 'غير فعال',
                        child: Text('غير فعال'),
                      ),
                    ],
                    onChanged: (value) {
                      // TODO: Implement status filter
                    },
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: 'كل الأقسام',
                    items: const [
                      DropdownMenuItem(
                        value: 'كل الأقسام',
                        child: Text('كل الأقسام'),
                      ),
                      // TODO: Add department items dynamically
                    ],
                    onChanged: (value) {
                      // TODO: Implement department filter
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'بحث عن المقاتلين...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Employees Table
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('الإجراءات')),
                    DataColumn(label: Text('الحالة')),
                    DataColumn(label: Text('تاريخ التعيين')),
                    DataColumn(label: Text('رقم الهاتف')),
                    DataColumn(label: Text('القسم')),
                    DataColumn(label: Text('الاسم')),
                    DataColumn(label: Text('الرقم التعريفي')),
                  ],
                  rows: List.generate(
                    10,
                    (index) => DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'حذف',
                                onPressed: () {
                                  // TODO: Implement delete functionality
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.qr_code),
                                tooltip: 'رمز QR',
                                onPressed: () {
                                  // TODO: Show QR code
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'تعديل',
                                onPressed: () {
                                  // TODO: Implement edit functionality
                                },
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'فعال',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ),
                        const DataCell(Text('2024-01-01')),
                        const DataCell(Text('+1234567890')),
                        const DataCell(Text('تقنية المعلومات')),
                        const DataCell(Text('محمد أحمد علي')),
                        DataCell(Text('EMP${1000 + index}')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 