# Spec: SP21 — CI chạy bộ test trên macOS

- Ngày: 2026-10-23 · Branch: `claude/intelligent-volta-famesh` (chỉ spec)
- Interface: không đổi. Đây là hạ tầng test, không thuộc stage SDLC nào.

## 1. Vấn đề

`AGENTS.md` § Code cam kết engine chỉ dùng POSIX sh + awk + sed + git, không bashism, ERE không `{n}`
(mawk). Nhưng `.github/workflows/kiem-tra.yml` chỉ chạy trên `ubuntu-latest`, nơi `sh` là dash, `awk` là
mawk, `sed` là GNU sed.

Người dùng `aw` trên macOS gặp ba công cụ khác hẳn:

- `/bin/sh` là bash 3.2 ở chế độ POSIX;
- `awk` là BSD awk (one-true-awk);
- `sed` là BSD sed.

Không có gì bảo đảm engine chạy đúng ở đó. Lỗi chỉ lộ khi người dùng gặp.

Rà nhanh mã hiện tại thấy engine đã tránh phần lớn lệnh chỉ có ở GNU:

- `sha256` có nhánh `shasum` (`tools/lib/sha256.sh`, `bin/aw`);
- `sed -i` dùng dạng `-i.bak` di động được;
- số luồng lấy bằng `getconf _NPROCESSORS_ONLN`;
- không có `stat -c`, `date -d`, `readlink -f`, `grep -P`.

Phần chưa rà được bằng mắt là hành vi của awk và sed: regex, `printf "%b"`, `-v` có escape, `sub`/`gsub`
với ký tự đặc biệt, locale UTF-8 khi `length()` gặp tiếng Việt.

## 2. Thiết kế

- `kiem-tra.yml`: job `kiem-tra` chạy trên `strategy.matrix.os: [ubuntu-latest, macos-latest]`,
  `fail-fast: false`. Bước `check-release.sh` chỉ chạy trên Ubuntu, vì nó kiểm version chứ không kiểm
  nền tảng. Bước test chạy trên cả hai.
- In phiên bản công cụ ở đầu job để đọc log dễ hơn: `sh --version || true`, `awk -W version || awk --version || true`,
  `sed --version || true`, `git --version`.
- **Không** cài GNU coreutils/gawk trên macOS, vì như vậy mất ý nghĩa của job.
- **Sửa những gì job macOS làm đỏ, trong cùng PR.** Mỗi lỗi nền tảng sửa trong engine, không sửa trong
  test, trừ khi chính test dùng lệnh không di động. Không bỏ ca, không đánh dấu `continue-on-error`.
- Lỗi cần sửa lớn hơn một PR → PR này chỉ thêm job và sửa các lỗi nhỏ. Phần còn lại ghi thành dự án con
  mới trên roadmap. Job macOS vẫn chạy, nhưng chưa thành check bắt buộc của branch protection cho tới khi
  xanh. Bật bắt buộc là việc người làm trong cài đặt repo.
- `run-tests.sh` không đổi. Nếu runner macOS (3 lõi) chạy quá chậm, đặt `AW_TEST_JOBS` trong job thay vì
  đổi script.

## 3. Test

- PR phải có một lần chạy CI xanh trên cả hai OS. Đây là bằng chứng chính.
- Mỗi lỗi nền tảng sửa được → thêm một ca vào phần test cùng chủ đề, tái hiện lỗi đó.
  Ví dụ: `length()` của chuỗi có dấu → phần `05-review-quality` hay nơi dùng nó. Ca phải chạy được cả trên
  Ubuntu.

## 4. Tài liệu

- README § Chạy test và phát hành: CI chạy Ubuntu + macOS.
- `AGENTS.md` § Code: thêm câu "CI chạy cả BSD awk/sed (macOS)", để người viết code biết dash/mawk không
  phải giới hạn duy nhất.
- `changes/…`, mục `Nội bộ`. Thêm mục `Sửa` cho từng lỗi người dùng macOS từng gặp.

## 5. Cần người duyệt

- Có bật job macOS thành check bắt buộc ngay khi xanh không. Đề xuất: có.
- Thời gian CI tăng, vì runner macOS chậm hơn và tính phút gấp 10 với repo private. Repo public thì không
  tốn phí.
