<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Menu;
use App\Models\MenuCategory;

class MenuController extends Controller
{
    public function index()
    {
        $menus = Menu::with('category', 'user')->latest()->get();
        return view('admin.menus.index', compact('menus'));
    }

    public function create()
    {
        $categories = MenuCategory::all();
        return view('admin.menus.create', compact('categories'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'category_id' => 'required|exists:menu_categories,category_id',
            'description' => 'nullable',
            'image' => 'nullable|image|max:2048'
        ]);

        try {
            $imagePath = null;

            if ($request->hasFile('image')) {
                $imagePath = $request->file('image')->store('menus', 'public');
            }

            Menu::create([
                'name' => $request->name,
                'category_id' => $request->category_id,
                'description' => $request->description,
                'image' => $imagePath,
                'user_id' => auth()->id(),
                'available' => true
            ]);

            return redirect()->route('menus.index')
                ->with('success', 'Menu created successfully');

        } catch (\Exception $e) {
            return back()->with('error', 'Failed to create menu');
        }
    }

    public function edit($id)
    {
        $menu = Menu::findOrFail($id);
        $categories = MenuCategory::all();

        return view('admin.menus.edit', compact('menu', 'categories'));
    }

    public function update(Request $request, $id)
    {
        $menu = Menu::findOrFail($id);

        $request->validate([
            'name' => 'required',
            'category_id' => 'required|exists:menu_categories,category_id',
            'description' => 'nullable',
            'image' => 'nullable|image|max:2048'
        ]);

        try {
            $imagePath = $menu->image;

            if ($request->hasFile('image')) {
                $imagePath = $request->file('image')->store('menus', 'public');
            }

            $menu->update([
                'name' => $request->name,
                'category_id' => $request->category_id,
                'description' => $request->description,
                'image' => $imagePath,
                'available' => $request->has('available')
            ]);

            return redirect()->route('menus.index')
                ->with('success', 'Menu updated successfully');

        } catch (\Exception $e) {
            return back()->with('error', 'Failed to update menu');
        }
    }

    public function destroy($id)
    {
        try {
            Menu::findOrFail($id)->delete();

            return redirect()->route('menus.index')
                ->with('success', 'Menu moved to trash successfully');

        } catch (\Exception $e) {
            return redirect()->route('menus.index')
                ->with('error', 'Failed to delete menu');
        }
    }

    public function trashed()
    {
        $menus = Menu::onlyTrashed()->with('category')->latest()->get();
        return view('admin.menus.trashed', compact('menus'));
    }

    public function restore($id)
    {
        try {
            $menu = Menu::onlyTrashed()->findOrFail($id);
            $menu->restore();

            return redirect()->route('menus.index')
                ->with('success', 'Menu restored successfully');

        } catch (\Exception $e) {
            return redirect()->route('menus.index')
                ->with('error', 'Failed to restore menu');
        }
    }

    // Mobile API

    public function apiIndex(Request $request)
    {
        $sort = $request->query('sort');

        $query = Menu::with('category')->where('available', true);

        if ($sort === 'best_seller') {
            $query->leftJoin('order_items', 'menus.menu_id', '=', 'order_items.menu_id')
                ->select('menus.*', \DB::raw('COUNT(order_items.menu_id) as order_count'))
                ->groupBy('menus.menu_id')
                ->orderBy('order_count', 'desc');
        } elseif ($sort === 'popular') {
            $thirtyDaysAgo = \Carbon\Carbon::now()->subDays(30);

            $query->leftJoin('order_items', 'menus.menu_id', '=', 'order_items.menu_id')
                ->leftJoin('orders', function($join) use ($thirtyDaysAgo) {
                    $join->on('order_items.order_id', '=', 'orders.order_id')
                         ->where('orders.created_at', '>=', $thirtyDaysAgo);
                })
                ->select('menus.*', \DB::raw('COUNT(orders.order_id) as recent_order_count'))
                ->groupBy('menus.menu_id')
                ->orderBy('recent_order_count', 'desc');
        } else {
            $query->latest();
        }

        return response()->json($query->get());
    }

    public function apiShow($id)
    {
        $menu = Menu::with('category')->findOrFail($id);
        return response()->json($menu);
    }
}