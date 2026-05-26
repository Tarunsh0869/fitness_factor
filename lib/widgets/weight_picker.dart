import 'package:flutter/material.dart';

class WeightPicker extends StatelessWidget {
  const WeightPicker({
    super.key,
    required this.metric,
    required this.major,
    required this.decimal,
    required this.onMetricChanged,
    required this.onMajorChanged,
    required this.onDecimalChanged,
  });

  final bool metric;
  final int major;
  final int decimal;
  final ValueChanged<bool> onMetricChanged;
  final ValueChanged<int> onMajorChanged;
  final ValueChanged<int> onDecimalChanged;

  @override
  Widget build(BuildContext context) {
    final majors = metric
        ? List<int>.generate(181, (i) => i + 30)
        : List<int>.generate(331, (i) => i + 70);

    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F2ED),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _toggle('Metric', metric, () => onMetricChanged(true)),
              _toggle('Imperial', !metric, () => onMetricChanged(false)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F2ED),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                '$major,$decimal ${metric ? 'kg' : 'lb'}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2A323E),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: Row(
                  children: [
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 42,
                        perspective: 0.003,
                        diameterRatio: 1.6,
                        physics: const FixedExtentScrollPhysics(),
                        controller: FixedExtentScrollController(
                          initialItem: majors.indexOf(major),
                        ),
                        onSelectedItemChanged: (index) =>
                            onMajorChanged(majors[index]),
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: majors.length,
                          builder: (context, index) {
                            final value = majors[index];
                            final selected = value == major;
                            return Center(
                              child: Text(
                                '$value',
                                style: TextStyle(
                                  fontSize: selected ? 30 : 22,
                                  color: selected
                                      ? const Color(0xFF2A323E)
                                      : const Color(0xFF7A8582),
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 42,
                        perspective: 0.003,
                        diameterRatio: 1.6,
                        physics: const FixedExtentScrollPhysics(),
                        controller: FixedExtentScrollController(
                          initialItem: decimal,
                        ),
                        onSelectedItemChanged: onDecimalChanged,
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 10,
                          builder: (context, index) {
                            final selected = index == decimal;
                            return Center(
                              child: Text(
                                '$index',
                                style: TextStyle(
                                  fontSize: selected ? 30 : 22,
                                  color: selected
                                      ? const Color(0xFF2A323E)
                                      : const Color(0xFF7A8582),
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggle(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF2A323E)
                  : const Color(0xFF7A8582),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
