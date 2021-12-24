
int get_index (uint32[] arr, int val) {

    for (int i = 0; i < arr.length; i++) {
        if (arr[i] == val) {
            return i;
        }
    }
    return -1;
}
