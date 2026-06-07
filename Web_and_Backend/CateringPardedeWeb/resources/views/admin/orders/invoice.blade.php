<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Invoice ORD-{{ str_pad($order->order_id, 5, '0', STR_PAD_LEFT) }}</title>
    <style>
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            color: #2D3748;
            margin: 0;
            padding: 0;
            font-size: 14px;
            line-height: 1.5;
        }
        .invoice-box {
            max-width: 800px;
            margin: auto;
            padding: 10px;
        }
        .header-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
        }
        .header-table td {
            vertical-align: top;
        }
        .brand-title {
            font-size: 26px;
            font-weight: bold;
            color: #1A365D;
            margin: 0 0 5px 0;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .brand-subtitle {
            font-size: 12px;
            color: #718096;
            margin: 0;
        }
        .invoice-title {
            font-size: 30px;
            font-weight: 300;
            color: #2D3748;
            text-align: right;
            margin: 0 0 5px 0;
            text-transform: uppercase;
            letter-spacing: 2px;
        }
        .invoice-meta {
            text-align: right;
            font-size: 12px;
            color: #718096;
        }
        .details-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
            background: #F7FAFC;
            border-radius: 8px;
        }
        .details-table td {
            padding: 15px;
            vertical-align: top;
            width: 50%;
        }
        .details-heading {
            font-weight: bold;
            color: #2D3748;
            border-bottom: 2px solid #E2E8F0;
            padding-bottom: 5px;
            margin-bottom: 10px;
            text-transform: uppercase;
            font-size: 11px;
            letter-spacing: 0.5px;
        }
        .details-content p {
            margin: 0 0 6px 0;
            color: #4A5568;
            font-size: 13px;
        }
        .details-content strong {
            color: #2D3748;
        }
        .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
        }
        .items-table th {
            background: #1A365D;
            color: #FFFFFF;
            text-align: left;
            padding: 10px 12px;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .items-table td {
            padding: 12px;
            border-bottom: 1px solid #E2E8F0;
            vertical-align: middle;
        }
        .items-table tr.item-row:nth-child(even) {
            background-color: #F7FAFC;
        }
        .items-table .text-right {
            text-align: right;
        }
        .items-table .text-center {
            text-align: center;
        }
        .addition-section-header {
            background-color: #EDF2F7;
            font-weight: bold;
            font-size: 12px;
            color: #2D3748;
            padding: 8px 12px;
            border-bottom: 2px solid #CBD5E0;
        }
        .summary-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        .summary-table td {
            padding: 6px 12px;
            font-size: 13px;
        }
        .summary-table .label {
            text-align: right;
            color: #718096;
            width: 80%;
        }
        .summary-table .value {
            text-align: right;
            font-weight: bold;
            color: #2D3748;
            width: 20%;
        }
        .summary-table tr.total-row td {
            padding-top: 15px;
            border-top: 2px solid #E2E8F0;
        }
        .summary-table tr.total-row .value {
            font-size: 18px;
            color: #1A365D;
        }
        .summary-table tr.balance-row td {
            padding-top: 8px;
            padding-bottom: 8px;
            background-color: #FFF5F5;
        }
        .summary-table tr.balance-row .value {
            color: #C53030;
        }
        .footer-note {
            margin-top: 40px;
            text-align: center;
            font-size: 12px;
            color: #A0AEC0;
            border-top: 1px solid #E2E8F0;
            padding-top: 15px;
        }
        .signature-container {
            margin-top: 50px;
            width: 100%;
            border-collapse: collapse;
        }
        .signature-container td {
            width: 50%;
            text-align: center;
            vertical-align: bottom;
            height: 100px;
        }
        .signature-line {
            width: 200px;
            margin: 0 auto;
            border-bottom: 1px solid #718096;
            padding-top: 50px;
        }
        .signature-title {
            font-size: 12px;
            color: #718096;
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <div class="invoice-box">
        <!-- Header -->
        <table class="header-table">
            <tr>
                <td>
                    <h1 class="brand-title">PARDEDE CATERING</h1>
                    <p class="brand-subtitle">
                        Jl. Sisingamangaraja No. 45, Balige<br>
                        Toba, Sumatera Utara, 22312<br>
                        Telp: 0812-3456-7890 | Email: info@pardedecatering.com
                    </p>
                </td>
                <td>
                    <h2 class="invoice-title">INVOICE</h2>
                    <div class="invoice-meta">
                        <strong>Invoice No:</strong> #INV/{{ date('Ymd') }}/{{ str_pad($order->order_id, 5, '0', STR_PAD_LEFT) }}<br>
                        <strong>Order Date:</strong> {{ $order->order_date ? $order->order_date->format('d M Y') : '-' }}<br>
                        <strong>Invoice Date:</strong> {{ date('d M Y') }}
                    </div>
                </td>
            </tr>
        </table>

        <!-- Details -->
        <table class="details-table">
            <tr>
                <td>
                    <div class="details-heading">DITAGIHKAN KEPADA:</div>
                    <div class="details-content">
                        <p><strong>Nama:</strong> {{ $order->user->name }}</p>
                        <p><strong>Telepon:</strong> {{ $order->user->phone ?? '-' }}</p>
                        <p><strong>Email:</strong> {{ $order->user->email }}</p>
                        <p><strong>Alamat Acara:</strong> {{ $order->event_address }}</p>
                    </div>
                </td>
                <td>
                    <div class="details-heading">DETAIL ACARA:</div>
                    <div class="details-content">
                        <p><strong>Tanggal Acara:</strong> {{ $order->event_date ? $order->event_date->format('d M Y') : '-' }}</p>
                        <p><strong>Jumlah Porsi (Pax):</strong> {{ $order->people }} pax</p>
                        <p><strong>Status Pesanan:</strong> {{ strtoupper($order->status->status_name) }}</p>
                        <p><strong>Catatan:</strong> {{ $order->notes ?? '-' }}</p>
                    </div>
                </td>
            </tr>
        </table>

        <!-- Items -->
        <table class="items-table">
            <thead>
                <tr>
                    <th style="width: 50%;">Menu / Item</th>
                    <th class="text-center" style="width: 15%;">Porsi</th>
                    <th class="text-right" style="width: 35%;">Subtotal Item</th>
                </tr>
            </thead>
            <tbody>
                <!-- Main Order Paket -->
                <tr class="item-row">
                    <td>
                        <strong>Paket Katering Utama</strong><br>
                        <span style="font-size: 11px; color: #718096;">
                            Menus: 
                            @foreach($order->items as $index => $item)
                                {{ $item->menu->name ?? 'Unknown Item' }}{{ $index < count($order->items) - 1 ? ', ' : '' }}
                            @endforeach
                        </span>
                    </td>
                    <td class="text-center">{{ $order->people }} pax</td>
                    <td class="text-right">
                        @if($order->final_price)
                            Rp {{ number_format($order->final_price, 0, ',', '.') }}
                        @else
                            <span style="color: #DD6B20; font-style: italic; font-weight: bold;">MENUNGGU NEGOSIASI</span>
                        @endif
                    </td>
                </tr>

                <!-- Additions Section -->
                @php
                    $approvedAdditions = $order->additions->where('status_id', 2);
                    $additionsTotal = 0;
                @endphp
                @if($approvedAdditions->isNotEmpty())
                    <tr>
                        <td colspan="3" class="addition-section-header">Tambahan Menu (Approved)</td>
                    </tr>
                    @foreach($approvedAdditions as $addition)
                        @foreach($addition->items as $additem)
                            @php
                                $itemPrice = $additem->final_price ?? 0;
                                $additionsTotal += $itemPrice;
                            @endphp
                            <tr class="item-row">
                                <td>
                                    <strong>{{ $additem->menu->name ?? 'Unknown Item' }}</strong><br>
                                    <span style="font-size: 11px; color: #718096;">Request Tambahan (#{{ $addition->id }})</span>
                                </td>
                                <td class="text-center">{{ $order->people }} pax</td>
                                <td class="text-right">Rp {{ number_format($itemPrice, 0, ',', '.') }}</td>
                            </tr>
                        @endforeach
                    @endforeach
                @endif
            </tbody>
        </table>

        <!-- Totals Summary -->
        <table class="summary-table">
            <tr>
                <td class="label">Total Paket Utama:</td>
                <td class="value">
                    @if($order->final_price)
                        Rp {{ number_format($order->final_price, 0, ',', '.') }}
                    @else
                        Rp 0
                    @endif
                </td>
            </tr>
            @if($additionsTotal > 0)
                <tr>
                    <td class="label">Total Menu Tambahan:</td>
                    <td class="value">Rp {{ number_format($additionsTotal, 0, ',', '.') }}</td>
                </tr>
            @endif
            
            @php
                $basePrice = (float)($order->final_price ?? 0);
                $grandTotal = $basePrice + $additionsTotal;
                $paid = (float)($order->total_paid ?? 0);
                $balance = max(0, $grandTotal - $paid);
            @endphp

            <tr class="total-row">
                <td class="label">Total Keseluruhan (Grand Total):</td>
                <td class="value">Rp {{ number_format($grandTotal, 0, ',', '.') }}</td>
            </tr>
            <tr>
                <td class="label">Jumlah Dibayar:</td>
                <td class="value" style="color: #2F855A;">Rp {{ number_format($paid, 0, ',', '.') }}</td>
            </tr>
            <tr class="balance-row">
                <td class="label">Sisa Pembayaran:</td>
                <td class="value">Rp {{ number_format($balance, 0, ',', '.') }}</td>
            </tr>
        </table>

        <!-- Signatures -->
        <table class="signature-container">
            <tr>
                <td>
                    <p class="signature-title">Hormat Kami,</p>
                    <div class="signature-line"></div>
                    <p style="font-weight: bold; margin: 5px 0 0 0;">Pardede Catering</p>
                </td>
                <td>
                    <p class="signature-title">Pelanggan,</p>
                    <div class="signature-line"></div>
                    <p style="font-weight: bold; margin: 5px 0 0 0;">{{ $order->user->name }}</p>
                </td>
            </tr>
        </table>

        <!-- Footer -->
        <div class="footer-note">
            Terima kasih telah mempercayakan konsumsi acara Anda kepada Pardede Catering.<br>
            Jika Anda memiliki pertanyaan tentang invoice ini, silakan hubungi kami.
        </div>
    </div>
</body>
</html>
