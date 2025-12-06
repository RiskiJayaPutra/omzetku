<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            if (!Schema::hasColumn('transactions', 'product_id')) {
                $table->foreignId('product_id')->nullable()->constrained()->onDelete('set null');
            }
            if (!Schema::hasColumn('transactions', 'quantity')) {
                $table->integer('quantity')->nullable();
            }
            if (!Schema::hasColumn('transactions', 'subcategory')) {
                $table->string('subcategory')->nullable();
            }
            if (!Schema::hasColumn('transactions', 'custom_category')) {
                $table->string('custom_category')->nullable();
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->dropForeign(['product_id']);
            $table->dropColumn(['product_id', 'quantity', 'subcategory', 'custom_category']);
        });
    }
};
