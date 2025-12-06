<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class TransactionController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = Transaction::where('user_id', $request->user()->id)
            ->orderBy('date_time', 'desc');

        // Filter by date if provided
        if ($request->has('date')) {
            $query->whereDate('date_time', $request->date);
        }

        // Filter by type if provided
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        $transactions = $query->get();

        return response()->json([
            'success' => true,
            'data' => $transactions
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'type' => 'required|in:Pemasukan,Pengeluaran',
            'category' => 'required|string|max:255',
            'amount' => 'required|numeric',
            'date_time' => 'required|date',
            'notes' => 'nullable|string',
            'product_id' => 'nullable|exists:products,id',
            'quantity' => 'nullable|integer|min:1',
            'subcategory' => 'nullable|string|max:255',
            'custom_category' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $transaction = Transaction::create([
            'user_id' => $request->user()->id,
            'title' => $request->title,
            'type' => $request->type,
            'category' => $request->category,
            'amount' => $request->amount,
            'date_time' => $request->date_time,
            'notes' => $request->notes,
            'product_id' => $request->product_id,
            'quantity' => $request->quantity,
            'subcategory' => $request->subcategory,
            'custom_category' => $request->custom_category,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Transaction created successfully',
            'data' => $transaction
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Request $request, $id)
    {
        $transaction = Transaction::where('user_id', $request->user()->id)
            ->find($id);

        if (!$transaction) {
            return response()->json([
                'success' => false,
                'message' => 'Transaction not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $transaction
        ]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $id)
    {
        $transaction = Transaction::where('user_id', $request->user()->id)
            ->find($id);

        if (!$transaction) {
            return response()->json([
                'success' => false,
                'message' => 'Transaction not found'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'string|max:255',
            'type' => 'in:Pemasukan,Pengeluaran',
            'category' => 'string|max:255',
            'amount' => 'numeric',
            'date_time' => 'date',
            'notes' => 'nullable|string',
            'product_id' => 'nullable|exists:products,id',
            'quantity' => 'nullable|integer|min:1',
            'subcategory' => 'nullable|string|max:255',
            'custom_category' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $transaction->update($request->only([
            'title', 'type', 'category', 'amount', 'date_time', 'notes', 'product_id', 'quantity', 'subcategory', 'custom_category'
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Transaction updated successfully',
            'data' => $transaction
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Request $request, $id)
    {
        $transaction = Transaction::where('user_id', $request->user()->id)
            ->find($id);

        if (!$transaction) {
            return response()->json([
                'success' => false,
                'message' => 'Transaction not found'
            ], 404);
        }

        $transaction->delete();

        return response()->json([
            'success' => true,
            'message' => 'Transaction deleted successfully'
        ]);
    }

    /**
     * Search transactions.
     */
    public function search(Request $request)
    {
        $query = $request->input('q', '');

        $transactions = Transaction::where('user_id', $request->user()->id)
            ->where(function ($q) use ($query) {
                $q->where('title', 'like', "%{$query}%")
                    ->orWhere('category', 'like', "%{$query}%")
                    ->orWhere('notes', 'like', "%{$query}%");
            })
            ->orderBy('date_time', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $transactions
        ]);
    }

    /**
     * Get transaction statistics.
     */
    public function statistics(Request $request)
    {
        $userId = $request->user()->id;

        // Get date range
        $startDate = $request->input('start_date', now()->startOfMonth());
        $endDate = $request->input('end_date', now()->endOfMonth());

        $transactions = Transaction::where('user_id', $userId)
            ->whereBetween('date_time', [$startDate, $endDate])
            ->get();

        $pemasukan = $transactions->where('type', 'Pemasukan')->sum('amount');
        $pengeluaran = $transactions->where('type', 'Pengeluaran')->sum('amount');
        $saldo = $pemasukan - abs($pengeluaran);

        return response()->json([
            'success' => true,
            'data' => [
                'pemasukan' => $pemasukan,
                'pengeluaran' => abs($pengeluaran),
                'saldo' => $saldo,
                'total_transactions' => $transactions->count(),
            ]
        ]);
    }
    /**
     * Reset all transactions (Delete All).
     */
    public function reset(Request $request)
    {
        Transaction::where('user_id', $request->user()->id)->delete();

        return response()->json([
            'success' => true,
            'message' => 'All transactions deleted successfully'
        ]);
    }

    /**
     * Import transactions (Restore).
     */
    public function import(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'transactions' => 'required|array',
            'transactions.*.title' => 'required|string',
            'transactions.*.type' => 'required|in:Pemasukan,Pengeluaran',
            'transactions.*.category' => 'required|string',
            'transactions.*.amount' => 'required|numeric',
            'transactions.*.date_time' => 'required|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $userId = $request->user()->id;
        $count = 0;

        foreach ($request->transactions as $data) {
            Transaction::create([
                'user_id' => $userId,
                'title' => $data['title'],
                'type' => $data['type'],
                'category' => $data['category'],
                'amount' => $data['amount'],
                'date_time' => $data['date_time'],
                'notes' => $data['notes'] ?? null,
                'product_id' => $data['product_id'] ?? null,
                'quantity' => $data['quantity'] ?? null,
                'subcategory' => $data['subcategory'] ?? null,
                'custom_category' => $data['custom_category'] ?? null,
            ]);
            $count++;
        }

        return response()->json([
            'success' => true,
            'message' => "$count transactions imported successfully"
        ]);
    }
}
