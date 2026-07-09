import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/add_event_controller.dart';
import 'package:mow_events/features/event/presentation/screens/add_event_screen.dart';

class EditEventScreen extends StatelessWidget {
  const EditEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final event = Get.arguments as EventModel?;
    return EventFormWidget(mode: EventFormMode.edit, initialEvent: event);
  }
}
