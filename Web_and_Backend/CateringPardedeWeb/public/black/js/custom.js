function previewImage(event) {
    const input = event.target;
    const preview = document.getElementById('preview-image');

    if (input.files && input.files[0]) {
        const reader = new FileReader();

        reader.onload = function(e) {
            preview.src = e.target.result;
            preview.style.display = 'block';
        }

        reader.readAsDataURL(input.files[0]);
    }
}

// DELETE CONFIRMATION (global)
$(document).on('click', '.btn-delete', function () {
    let form = $(this).closest('form');
    let name = $(this).data('name') || 'this item';

    Swal.fire({
        title: 'Are you sure?',
        text: 'Delete "' + name + '"?',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#e14eca',
        cancelButtonColor: '#6c757d',
        confirmButtonText: 'Yes, delete it!',
        background: '#27293d',
        color: '#fff'
    }).then((result) => {
        if (result.isConfirmed) {
            form.submit();
        }
    });
});

// FLASH ALERTS (global)
if (typeof flashSuccess !== 'undefined') {
    Swal.fire({
        icon: 'success',
        title: 'Success',
        text: flashSuccess,
        timer: 2000,
        showConfirmButton: false,
        background: '#27293d',
        color: '#fff'
    });
}

if (typeof flashError !== 'undefined') {
    Swal.fire({
        icon: 'error',
        title: 'Error',
        text: flashError,
        background: '#27293d',
        color: '#fff'
    });
}