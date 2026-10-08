import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'domain/models/group.dart';
import 'domain/models/person.dart';
import 'domain/models/expense.dart';
import 'domain/models/settlement_payment.dart';
import 'logic/balance_calculator.dart';
import 'logic/settlement_calculator.dart';

void main() {
  runApp(const GastosCompartidosApp());
}

class GastosCompartidosApp extends StatelessWidget {
  const GastosCompartidosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gastos Compartidos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Group> groups;

  @override
  void initState() {
    super.initState();
    // Datos de demostración iniciales
    final p1 = Person(id: '1', name: 'Luciano');
    final p2 = Person(id: '2', name: 'Ana');
    final p3 = Person(id: '3', name: 'Carlos');

    final expense1 = Expense(
      description: 'Cena de bienvenida',
      amount: 15000.0,
      payer: p1,
      participants: [p1, p2, p3],
    );

    final demoGroup = Group(
      id: 'demo-1',
      name: 'Viaje a la Costa',
      colorHex: '#2563EB',
      iconName: 'flight',
      members: [p1, p2, p3],
      expenses: [expense1],
    );

    groups = [demoGroup];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Grupos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
      ),
      body: groups.isEmpty
          ? const Center(
              child: Text(
                'No hay grupos creados.\nToca "+" para comenzar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final balances = BalanceCalculator.calculateMemberBalances(group);
                final settlements = SettlementCalculator.suggestFormattedSettlements(balances);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      _showGroupDetail(context, group, balances, settlements);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                child: const Icon(Icons.group, color: Color(0xFF2563EB)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${group.members.length} miembros • ${group.expenses.length} gastos',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                          if (settlements.isNotEmpty) ...[
                            const Divider(height: 24),
                            Row(
                              children: [
                                const Icon(Icons.sync_alt, size: 16, color: Colors.amber),
                                const SizedBox(width: 6),
                                Text(
                                  '${settlements.length} pago(s) pendiente(s)',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Próximamente: modal de creación de grupo
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Grupo'),
      ),
    );
  }

  void _showGroupDetail(
    BuildContext context,
    Group group,
    List balances,
    List<FormattedSettlement> settlements,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    group.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pagos Sugeridos para Liquidar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (settlements.isEmpty)
                    const Text('¡Todas las cuentas están saldadas!')
                  else
                    ...settlements.map((s) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.arrow_forward, color: Colors.green),
                            title: Text('${s.payerName} paga a ${s.payeeName}'),
                            trailing: Text(
                              s.formattedAmount,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        )),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
