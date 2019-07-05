$(document).on('turbolinks:load', () => {
  $('tr[data-controller]').off('click')

  $('tr[data-controller]').click((event) => {
    const controller = $(event.target.parentNode).data('controller')
    const id = $(event.target.parentNode).data('id')

    Turbolinks.visit(`/${controller}/${id}`)
  })

  if (!$.fn.dataTable.isDataTable('#students-table')) {
    $('#students-table').DataTable({
      paging: false,
      dom: '<"row"<"col d-flex align-items-center"B><"col"fr>><"row"t>',
      buttons: [
        'copyHtml5', 'csvHtml5', 'excelHtml5'
      ]
    })
  }

  if (!$.fn.dataTable.isDataTable('#homework-table')) {
    $('#homework-table').DataTable({
      dom: 'rtp',
      'pageLength': 5,
      'language': {
        'emptyTable': 'No homeworks have been found'
      }
    })
  }
})

if (!Turbolinks) {
  location.reload()
}

Turbolinks.dispatch('turbolinks:load')
