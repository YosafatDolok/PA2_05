@extends('layouts.app')

@section('content')

<h3>Menu List</h3>

<a href="{{ route('menus.create') }}">Add Menu</a>

<table border="1" cellpadding="10">
    <tr>
        <th>Name</th>
        <th>Category</th>
        <th>Available</th>
        <th>Action</th>
    </tr>

    @foreach($menus as $menu)
    <tr>
        <td>{{ $menu->name }}</td>
        <td>{{ $menu->category->name ?? '-' }}</td>
        <td>{{ $menu->available ? 'Yes' : 'No' }}</td>
        <td>
            <a href="{{ route('menus.edit', $menu->id) }}">Edit</a>

            <form action="{{ route('menus.destroy', $menu->id) }}" method="POST" style="display:inline;">
                @csrf
                @method('DELETE')
                <button type="submit">Delete</button>
            </form>
        </td>
    </tr>
    @endforeach

</table>

@endsection