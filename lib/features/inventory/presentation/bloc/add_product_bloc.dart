import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/use_cases/admin_add_product_use_case.dart';

// Events
abstract class AddProductEvent extends Equatable {
  const AddProductEvent();

  @override
  List<Object?> get props => [];
}

class SubmitProduct extends AddProductEvent {
  final String productId;
  final String name;
  final String unit;
  final int initialQuantity;
  final int reorderPoint;
  final String productType;

  const SubmitProduct({
    required this.productId,
    required this.name,
    required this.unit,
    required this.initialQuantity,
    required this.reorderPoint,
    required this.productType,
  });

  @override
  List<Object?> get props => [
    productId,
    name,
    unit,
    initialQuantity,
    reorderPoint,
    productType,
  ];
}

class ResetProductForm extends AddProductEvent {}

// States
abstract class AddProductState extends Equatable {
  const AddProductState();

  @override
  List<Object?> get props => [];
}

class AddProductInitial extends AddProductState {}

class AddProductLoading extends AddProductState {}

class AddProductSuccess extends AddProductState {
  final String productName;

  const AddProductSuccess(this.productName);

  @override
  List<Object?> get props => [productName];
}

class AddProductError extends AddProductState {
  final String message;

  const AddProductError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AddProductBloc extends Bloc<AddProductEvent, AddProductState> {
  final AdminAddProductUseCase addProductUseCase;

  AddProductBloc({required this.addProductUseCase})
    : super(AddProductInitial()) {
    on<SubmitProduct>(_onSubmitProduct);
    on<ResetProductForm>(_onResetForm);
  }

  Future<void> _onSubmitProduct(
    SubmitProduct event,
    Emitter<AddProductState> emit,
  ) async {
    emit(AddProductLoading());

    try {
      await addProductUseCase.execute(
        productId: event.productId,
        name: event.name,
        unit: event.unit,
        initialQuantity: event.initialQuantity,
        reorderPoint: event.reorderPoint,
        productType: event.productType,
      );

      emit(AddProductSuccess(event.name));
    } catch (e) {
      emit(AddProductError(e.toString()));
    }
  }

  void _onResetForm(ResetProductForm event, Emitter<AddProductState> emit) {
    emit(AddProductInitial());
  }
}
