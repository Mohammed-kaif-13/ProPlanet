import 'package:flutter/material.dart';
import '../../models/food_item_model.dart';

class CheckoutOptionsEditorScreen extends StatefulWidget {
  final List<CheckoutOption> initialOptions;

  const CheckoutOptionsEditorScreen({
    super.key,
    required this.initialOptions,
  });

  @override
  State<CheckoutOptionsEditorScreen> createState() =>
      _CheckoutOptionsEditorScreenState();
}

class _CheckoutOptionsEditorScreenState
    extends State<CheckoutOptionsEditorScreen> {
  List<CheckoutOption> _options = [];

  @override
  void initState() {
    super.initState();
    _options = List.from(widget.initialOptions);
  }

  void _addOption() {
    setState(() {
      _options.add(CheckoutOption(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'New Option',
        type: 'plastic',
        environmentalImpact: 'high',
        pointsReward: 10,
        pointsPenalty: 5,
        isDefault: false,
      ));
    });
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
  }

  void _updateOption(int index, CheckoutOption updatedOption) {
    setState(() {
      _options[index] = updatedOption;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Checkout Options'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_options);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Points System',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Points Reward: Given when user DECLINES the option\n'
                        'Points Penalty: Deducted when user SELECTS the option',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Options List
          Expanded(
            child: _options.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No checkout options',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add options',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _options.length,
                    itemBuilder: (context, index) {
                      return _OptionEditorCard(
                        option: _options[index],
                        onUpdate: (updated) => _updateOption(index, updated),
                        onDelete: () => _removeOption(index),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addOption,
        icon: const Icon(Icons.add),
        label: const Text('Add Option'),
      ),
    );
  }
}

class _OptionEditorCard extends StatefulWidget {
  final CheckoutOption option;
  final Function(CheckoutOption) onUpdate;
  final VoidCallback onDelete;

  const _OptionEditorCard({
    required this.option,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_OptionEditorCard> createState() => _OptionEditorCardState();
}

class _OptionEditorCardState extends State<_OptionEditorCard> {
  late TextEditingController _nameController;
  late TextEditingController _pointsRewardController;
  late TextEditingController _pointsPenaltyController;
  late String _selectedType;
  late String _selectedImpact;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.option.name);
    _pointsRewardController =
        TextEditingController(text: widget.option.pointsReward.toString());
    _pointsPenaltyController = TextEditingController(
        text: widget.option.pointsPenalty?.toString() ?? '0');
    _selectedType = widget.option.type;
    _selectedImpact = widget.option.environmentalImpact;
    _isDefault = widget.option.isDefault;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pointsRewardController.dispose();
    _pointsPenaltyController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    widget.onUpdate(CheckoutOption(
      id: widget.option.id,
      name: _nameController.text.trim(),
      type: _selectedType,
      environmentalImpact: _selectedImpact,
      pointsReward: int.tryParse(_pointsRewardController.text) ?? 0,
      pointsPenalty: int.tryParse(_pointsPenaltyController.text),
      isDefault: _isDefault,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isHarmful = _selectedType == 'plastic' && _selectedImpact == 'high';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isHarmful ? Colors.red.withOpacity(0.3) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isHarmful ? Icons.warning : Icons.check_circle,
                  color: isHarmful ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Option Name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _saveChanges(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Type
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: ['plastic', 'paper', 'eco-friendly']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
                _saveChanges();
              },
            ),

            const SizedBox(height: 12),

            // Environmental Impact
            DropdownButtonFormField<String>(
              value: _selectedImpact,
              decoration: const InputDecoration(
                labelText: 'Environmental Impact',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: ['high', 'medium', 'low']
                  .map((impact) => DropdownMenuItem(
                        value: impact,
                        child: Text(impact),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedImpact = value!;
                });
                _saveChanges();
              },
            ),

            const SizedBox(height: 12),

            // Points Reward
            TextFormField(
              controller: _pointsRewardController,
              decoration: const InputDecoration(
                labelText: 'Points Reward (if declined)',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.add_circle, color: Colors.green),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _saveChanges(),
            ),

            const SizedBox(height: 12),

            // Points Penalty
            TextFormField(
              controller: _pointsPenaltyController,
              decoration: const InputDecoration(
                labelText: 'Points Penalty (if selected)',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.remove_circle, color: Colors.red),
                helperText: 'Leave empty if no penalty',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _saveChanges(),
            ),

            const SizedBox(height: 12),

            // Default Selection
            CheckboxListTile(
              title: const Text('Selected by default'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value ?? false;
                });
                _saveChanges();
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Warning for harmful options
            if (isHarmful)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This option is harmful. Users will lose points if selected.',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                        ),
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


