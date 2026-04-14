@extends('layouts.app', ['page' => __('Dashboard')])

@section('content')
<div class="content">

    <div class="row">
        {{-- Total Users --}}
        <div class="col-lg-4">
            <div class="card card-stats">
                <div class="card-body">
                    <div class="numbers">
                        <p class="card-category">Total Users</p>
                        <h3 class="card-title">{{ $users ?? 0 }}</h3>
                    </div>
                </div>
            </div>
        </div>

        {{-- Total Orders --}}
        <div class="col-lg-4">
            <div class="card card-stats">
                <div class="card-body">
                    <div class="numbers">
                        <p class="card-category">Total Orders</p>
                        <h3 class="card-title">{{ $orders ?? 0 }}</h3>
                    </div>
                </div>
            </div>
        </div>

        {{-- Total Menus --}}
        <div class="col-lg-4">
            <div class="card card-stats">
                <div class="card-body">
                    <div class="numbers">
                        <p class="card-category">Total Menus</p>
                        <h3 class="card-title">{{ $menus ?? 0 }}</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- Welcome --}}
    <div class="row">
        <div class="col-12">
            <div class="card">
                <div class="card-body">
                    <h4>Welcome, {{ auth()->user()->name }}</h4>
                </div>
            </div>
        </div>
    </div>

    {{-- Quick Actions --}}
    <div class="row">
        <div class="col-12">
            <div class="card">
                <div class="card-header">
                    <h5 class="title">Quick Actions</h5>
                </div>
                <div class="card-body">

                    <a href="{{ route('menus.index') }}" class="btn btn-primary">
                        Manage Menus
                    </a>

                    <a href="{{ route('categories.index') }}" class="btn btn-info">
                        Manage Categories
                    </a>

                    <a href="{{ route('galleries.index') }}" class="btn btn-success">
                        Manage Galleries
                    </a>

                    <a href="#" class="btn btn-warning">
                        View Orders
                    </a>

                    <a href="#" class="btn btn-danger">
                        Manage Users
                    </a>

                </div>
            </div>
        </div>
    </div>

</div>
@endsection