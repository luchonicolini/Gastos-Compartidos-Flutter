import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/features/members/domain/member_name_disambiguator.dart';

void main() {
  group('MemberNameDisambiguator', () {
    test('isDuplicate reconoce nombres idénticos o con diferente mayúscula o espacios', () {
      final existing = ['Pedro', 'Ana', 'Carlos'];

      expect(MemberNameDisambiguator.isDuplicate('Pedro', existing), isTrue);
      expect(MemberNameDisambiguator.isDuplicate('pedro', existing), isTrue);
      expect(MemberNameDisambiguator.isDuplicate('  PEDRO  ', existing), isTrue);
      expect(MemberNameDisambiguator.isDuplicate('Juan', existing), isFalse);
      expect(MemberNameDisambiguator.isDuplicate('', existing), isFalse);
    });

    test('nextNumberedName sugiere (2) para un nombre repetido', () {
      final existing = ['Pedro'];
      expect(
        MemberNameDisambiguator.nextNumberedName('Pedro', existing),
        'Pedro (2)',
      );
    });

    test('nextNumberedName incrementa al siguiente número si (2) ya existe', () {
      final existing = ['Pedro', 'Pedro (2)'];
      expect(
        MemberNameDisambiguator.nextNumberedName('Pedro', existing),
        'Pedro (3)',
      );
    });

    test('nextNumberedName maneja nombres que ya tienen (2)', () {
      final existing = ['Pedro', 'Pedro (2)'];
      expect(
        MemberNameDisambiguator.nextNumberedName('Pedro (2)', existing),
        'Pedro (3)',
      );
    });

    test('getSuggestions devuelve lista con la sugerencia numerada si hay duplicado', () {
      final existing = ['Pedro'];
      expect(
        MemberNameDisambiguator.getSuggestions('Pedro', existing),
        ['Pedro (2)'],
      );
      expect(
        MemberNameDisambiguator.getSuggestions('Lucas', existing),
        isEmpty,
      );
    });
  });
}
