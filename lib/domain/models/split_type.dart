enum SplitType {
  equally('Igual'),
  byAmount('Por Monto Fijo'),
  byPercentage('Por Porcentaje'),
  byShares('Por Partes');

  final String localizedDescription;
  const SplitType(this.localizedDescription);
}
