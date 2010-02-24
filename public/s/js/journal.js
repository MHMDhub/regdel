$('document').ready(function() {

  // Add reldate for timestamps
  $("tr", $("#journal-table-entries")).find("td:first-child").addClass("reldate");

  // Relative date must be triggered before tablesorter so that all rows are
  // updated
  var mytime = "";
  var rltime = "";
  $(".reldate", $("#journal-table")).each(function () {
    mytime = new Date($(this).text()*1000);
    rltime = relativeDate(mytime);
    $(this).attr("title",mytime);
    $(this).text(rltime);
  });


  // Set navigation tab as active
  $("#nav-journal","#navigation").addClass("active");

  // Add edit column
  $("thead tr", $("#journal-table")).append('<th class="text-right">Edit</th>');

  // Modify journal rows
  $("tr", $("#journal-table-entries")).addClass("entry-row")
  .each(function () {
    // Add editlinks
    var myid = $(this).get(0).getAttribute('id');
    $(this).append('<td class="text-right notog"><a href="'+app_prefix+'/entry/edit/'+myid+'">edit</a></td>');
  })
  .parent().find("td:not(.notog)").toggle(
    // Show journal entry details
    function () {
      var myid = $(this).parent().get(0).getAttribute('id');
      get_journal_detail(myid);
    },
    // Remove journal entry details
    function () {
      $(".entry_detail",$("#journal-table-entries")).remove();
    }
  );

  // Setup tablesorter
  $("#journal-table", $("#page-content")).tablesorter({
  });

});

// Function to update DOM with accounts and amounts of journal entry
function get_journal_detail(myid,journal_table_entries) {
  $(".entry_detail",journal_table_entries).remove();
  $.getJSON(app_prefix+"/json/entry/"+myid, function(data) {
    $.each(data.credits, function(i, item) {
        var myamounts = '<tr class="entry_detail credit">';
        myamounts += '<td>'+item.account_id+'</td>';
        myamounts += '<td>'+item.memorandum+'</td>';
        myamounts += '<td/>';
        myamounts += '<td>'+item.to_usd+'</td>';
        myamounts += '<td></td>';
        myamounts += '</tr>';
        $("#"+myid,journal_table_entries).after(myamounts);
    });
    $.each(data.debits, function(i, item) {
        var myamounts = '<tr class="entry_detail debit">';
        myamounts += '<td>'+item.account_id+'</td>';
        myamounts += '<td>'+item.memorandum+'</td>';
        myamounts += '<td>'+item.to_usd+'</td>';
        myamounts += '<td></td>';
        myamounts += '<td></td>';
        myamounts += '</tr>';
        $("#"+myid,journal_table_entries).after(myamounts);
    });
  });
}
