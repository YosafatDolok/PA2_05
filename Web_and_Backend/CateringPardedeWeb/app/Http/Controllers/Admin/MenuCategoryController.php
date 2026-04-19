<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\MenuCategory;

class MenuCategoryController extends Controller
{
    public function index()
    {
        $categories = MenuCategory::latest()->get();
        return view('admin.categories.index', compact('categories'));
    }

    public function create()
    {
        return view('admin.categories.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|unique:menu_categories,name'
        ]);

        MenuCategory::create([
            'name' => $request->name
        ]);

        return redirect()->route('categories.index')
            ->with('success', 'Category created successfully');
    }

    public function edit($id)
    {
        $category = MenuCategory::findOrFail($id);
        return view('admin.categories.edit', compact('category'));
    }

    public function update(Request $request, $id)
    {
        $category = MenuCategory::findOrFail($id);

        $request->validate([
            'name' => 'required|unique:menu_categories,name,' . $id . ',category_id'
        ]);

        $category->update([
            'name' => $request->name
        ]);

        return redirect()->route('categories.index')
            ->with('success', 'Category updated successfully');
    }

    public function destroy($id)
    {
        try {
            MenuCategory::findOrFail($id)->delete();

            return redirect()->route('categories.index')
                ->with('success', 'Category deleted successfully');

        } catch (\Exception $e) {
            return redirect()->route('categories.index')
                ->with('error', 'Failed to delete category');
        }
    }
}