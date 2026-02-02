import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';

class MonthEventsBottomSheet extends StatelessWidget {
  final String monthTitle;
  final List<EventModel> events;

  const MonthEventsBottomSheet({
    super.key,
    required this.monthTitle,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.75,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                '${AppTexts.events} $monthTitle',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: events.isEmpty
                    ? Center(child: Text(AppTexts.thereAreNoEventsThisMonth))
                    : ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (_, i) {
                          final e = events[i];
                          return ListTile(
                            leading: Icon(Icons.event),
                            title: Text(e.name),
                            subtitle: Text('${e.startTime} - ${e.endTime}'),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
