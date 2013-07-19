test -> original data, no deleted column, trigger on delete inserts into test_archive with now() in deleted
test_archive -> deleted data + deleted column
test_full -> view union test + test_archive
