# Weekday label for the prompt's day segment.

weekday_glyph() {
  case "$(date +%u)" in
    1) printf '%s' 'Mon' ;;
    2) printf '%s' 'Tue' ;;
    3) printf '%s' 'Wed' ;;
    4) printf '%s' 'Thu' ;;
    5) printf '%s' 'Fri' ;;
    6) printf '%s' 'Sat' ;;
    7) printf '%s' 'Sun' ;;
  esac
}
