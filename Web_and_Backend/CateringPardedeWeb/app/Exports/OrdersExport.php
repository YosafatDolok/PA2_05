<?php

namespace App\Exports;

use App\Models\Order;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;

class OrdersExport implements FromCollection, WithHeadings, WithMapping
{
    protected $statusId;
    
    public function __construct($statusId = null)
    {
        $this->statusId = $statusId;
    }

    /**
    * @return \Illuminate\Support\Collection
    */
    public function collection()
    {
        $query = Order::with(['user', 'status', 'items.menu']);
        
        if ($this->statusId) {
            $query->where('status_id', $this->statusId);
        }
        
        return $query->orderBy('order_date', 'desc')->get();
    }

    /**
     * @return array
     */
    public function headings(): array
    {
        return [
            'Order ID',
            'Customer',
            'Email',
            'Menus',
            'Event Date',
            'People',
            'Total Price',
            'Total Paid',
            'Remaining Balance',
            'Status',
            'Order Created'
        ];
    }

    /**
    * @param mixed $order
    * @return array
    */
    public function map($order): array
    {
        return [
            'ORD-' . str_pad($order->order_id, 5, '0', STR_PAD_LEFT),
            $order->user->name,
            $order->user->email,
            $order->items->pluck('menu.name')->implode(', '),
            $order->event_date->format('d M Y'),
            $order->people,
            $order->total_payable,
            $order->total_paid,
            $order->remaining_balance,
            $order->status->status_name,
            $order->created_at->format('d M Y H:i')
        ];
    }
}
