// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_deck.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudyDeckAdapter extends TypeAdapter<StudyDeck> {
  @override
  final int typeId = 0;

  @override
  StudyDeck read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyDeck(
      id: fields[0] as String,
      title: fields[1] as String,
      flashcards: (fields[2] as List).cast<Flashcard>(),
      quizQuestions: (fields[3] as List).cast<QuizQuestion>(),
      createdAt: fields[4] as DateTime,
      lastReviewedAt: fields[5] as DateTime?,
      totalReviews: fields[6] as int,
      correctAnswers: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StudyDeck obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.flashcards)
      ..writeByte(3)
      ..write(obj.quizQuestions)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastReviewedAt)
      ..writeByte(6)
      ..write(obj.totalReviews)
      ..writeByte(7)
      ..write(obj.correctAnswers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyDeckAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
