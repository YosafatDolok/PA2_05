@extends('layouts.app')

@section('content')

<div class="col-md-8">
    <div class="card">
        <div class="card-header">
            <h4>Edit Profile</h4>
        </div>

        <div class="card-body">

            @if(session('success'))
                <div class="alert alert-success">{{ session('success') }}</div>
            @endif

            <form method="POST" action="{{ route('profile.update') }}" enctype="multipart/form-data">
                @csrf
                @method('PUT')

                <div class="form-group">
                    <label>Name</label>
                    <input type="text" name="name" value="{{ $user->name }}" class="form-control">
                </div>

                <div class="form-group">
                    <label>Email</label>
                    <input type="email" name="email" value="{{ $user->email }}" class="form-control">
                </div>

                <div class="form-group">
                    <label>Phone</label>
                    <input type="text" name="phone_number" value="{{ $user->phone_number }}" class="form-control">
                </div>

                <div class="form-group">
                    <label>Profile Picture</label><br>

                    @if($user->profile_picture)
                        <img src="{{ asset('storage/' . $user->profile_picture) }}" width="100"><br><br>
                    @endif

                    <input type="file" name="profile_picture">
                </div>

                <button class="btn btn-primary">Update</button>

            </form>

        </div>
    </div>
</div>

@endsection