import '../camera_types.dart';
import 'rep_counter.dart';

/// Plain-language copy for every internal verdict, including a successful rep.
String counterRejectionInstruction(CounterRejection rejection) =>
    switch (rejection) {
      CounterRejection.none => 'Rep counted.',
      CounterRejection.dwellTooShort => rejectionInstruction(RepRejection.shallow),
      CounterRejection.repTooFast || CounterRejection.debounce =>
        rejectionInstruction(RepRejection.tooFast),
      CounterRejection.bodyNotStraight => rejectionInstruction(RepRejection.bodyNotStraight),
      CounterRejection.torsoCollapsed => rejectionInstruction(RepRejection.torsoCollapsed),
      CounterRejection.lowConfidence => rejectionInstruction(RepRejection.lowConfidence),
      CounterRejection.lockoutMissed => rejectionInstruction(RepRejection.lockoutMissed),
      CounterRejection.notDeepEnough => rejectionInstruction(RepRejection.notDeepEnough),
    };
