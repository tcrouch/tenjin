$(document).on("turbolinks:load", () => {
  $(".challenge-row, .homework-row").off("click");

  $(".challenge-row, .homework-row").click(function (event) {
    const pickedSubject = $(event.target.parentNode).data("subject");
    const pickedTopic = $(event.target.parentNode).data("topic");
    const pickedLesson = $(event.target.parentNode).data("lesson");
    $(event.target).prop("disabled", true);

    $.ajax({
      type: "post",
      url: "/quizzes",
      data: {
        quiz: {
          subject: pickedSubject,
          topic_id: pickedTopic,
          lesson_id: pickedLesson,
        },
      },
      beforeSend: function (xhr) {
        xhr.setRequestHeader(
          "X-CSRF-Token",
          $('meta[name="csrf-token"]').attr("content"),
        );
      },
      success: function (data) {
        Turbolinks.visit("/quizzes");
      },
    });
  });
});
