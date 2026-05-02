<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';

use App\Models\Order;
use App\Models\OrderMessage;
use Illuminate\Support\Facades\DB;

$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "--- DIAGNOSTIC START ---\n";

$messageCount = OrderMessage::count();
echo "Total Messages: $messageCount\n";

$orderIdsWithMessages = OrderMessage::distinct()->pluck('order_id');
echo "Order IDs in messages: " . implode(', ', $orderIdsWithMessages->toArray()) . "\n";

foreach($orderIdsWithMessages as $id) {
    $exists = Order::where('order_id', $id)->exists();
    echo "Order #$id exists: " . ($exists ? 'YES' : 'NO') . "\n";
}

$admin = \App\Models\User::find(1);
echo "Admin Found: " . ($admin ? 'YES ('.$admin->name.')' : 'NO') . "\n";

echo "--- DIAGNOSTIC END ---\n";
