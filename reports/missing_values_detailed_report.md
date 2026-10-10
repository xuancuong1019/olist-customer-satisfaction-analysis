## 1. Phân tích missing values: `order_approved_at`

### 1.1. Phát hiện ban đầu

Trong quá trình kiểm tra chất lượng dữ liệu của bảng `staging.olist_orders`, phát hiện **14 đơn hàng có trạng thái `delivered` nhưng bị thiếu giá trị `order_approved_at`**.

Đây là trường hợp cần được kiểm tra thêm vì các đơn hàng đã hoàn tất giao hàng nhưng không có thời điểm phê duyệt đơn hàng được ghi nhận. Tuy nhiên, chưa thể kết luận ngay rằng đây là lỗi dữ liệu, bởi nguyên nhân thiếu timestamp có thể liên quan đến quy trình nghiệp vụ hoặc cách dữ liệu được ghi nhận.

### 1.2. Kiểm chứng theo phương thức thanh toán

Để xác định liệu tình trạng missing có liên quan đến một phương thức thanh toán cụ thể hay không, tiến hành so sánh tỷ lệ missing `order_approved_at` giữa các phương thức thanh toán của những đơn hàng có trạng thái `delivered`.

Kết quả cho thấy:

- Cả 14 đơn hàng bị thiếu `order_approved_at` đều sử dụng phương thức thanh toán `boleto`.
- Trong tổng số 19.191 đơn hàng `delivered` sử dụng `boleto`, có 14 đơn bị thiếu timestamp, tương đương khoảng **0,073%**.
- Các nhóm phương thức thanh toán còn lại không ghi nhận trường hợp missing trong kết quả kiểm tra.

Kết quả này cho thấy các trường hợp missing được phát hiện tập trung ở nhóm đơn hàng sử dụng `boleto`. Tuy nhiên, do số lượng trường hợp rất nhỏ so với tổng số đơn hàng trong nhóm, chưa đủ cơ sở để kết luận rằng phương thức thanh toán `boleto` là nguyên nhân trực tiếp.

### 1.3. Kiểm tra theo thời gian đặt hàng

Tiếp tục đối chiếu `order_purchase_timestamp` để xác định liệu các trường hợp missing có tập trung vào một số thời điểm nhất định hay không.

Kết quả cho thấy 14 đơn hàng được đặt vào các ngày:

- **19/01/2017:** 2 đơn hàng.
- **17–19/02/2017:** 12 đơn hàng.

Trong nhóm đơn `boleto` được kiểm tra ở các ngày 17–19/02/2017, tỷ lệ missing ghi nhận như sau:

| Ngày đặt hàng | Số đơn thiếu | Tổng đơn boleto | Tỷ lệ missing |
|---|---:|---:|---:|
| 17/02/2017 | 3 | 8 | 37,5% |
| 18/02/2017 | 8 | 10 | 80% |
| 19/02/2017 | 1 | 10 | 10% |

Đáng chú ý, tỷ lệ missing cao nhất xuất hiện vào ngày 18/02/2017. Điều này cho thấy các trường hợp thiếu timestamp không phân bố đồng đều theo ngày đặt hàng trong nhóm được kiểm tra.

Tuy nhiên, kết quả trên chỉ phản ánh sự tập trung của các trường hợp missing theo thời gian. Dữ liệu hiện có chưa đủ để xác định liệu đây là hệ quả của quy trình thanh toán `boleto`, lỗi hệ thống trong một khoảng thời gian hay một nguyên nhân khác.

### 1.4. Đối chiếu các mốc thời gian giao hàng

Để kiểm tra liệu những đơn hàng này có thực sự được xử lý và giao hàng hay không, tiếp tục đối chiếu các cột thời gian liên quan.

Kết quả cho thấy:

- Cả 14 đơn hàng đều có `order_delivered_carrier_date` và `order_delivered_customer_date`.
- Khoảng thời gian từ lúc đặt hàng đến khi bàn giao cho đơn vị vận chuyển dao động khoảng 4–8 ngày.
- Trong 14 đơn hàng, 12 đơn được bàn giao cho đơn vị vận chuyển vào ngày 22 hoặc 23/02/2017; hai đơn còn lại có ngày bàn giao là 25/01/2017 và 27/01/2017.

Những thông tin này cho thấy các đơn hàng đều có các mốc thời gian ghi nhận quá trình vận chuyển và giao hàng, mặc dù thiếu thời điểm phê duyệt.

Tuy nhiên, sự tồn tại của các mốc thời gian phía sau không giúp xác định chính xác thời điểm phê duyệt bị thiếu hoặc lý do giá trị này không được ghi nhận.

### 1.5. Kết luận và quyết định xử lý

Qua các bước kiểm tra, có thể xác nhận rằng 14 đơn hàng `delivered` bị thiếu `order_approved_at` đều thuộc nhóm thanh toán `boleto`, đồng thời tập trung vào một số ngày đặt hàng nhất định. Mặc dù đã đối chiếu phương thức thanh toán và các mốc thời gian liên quan, **chưa đủ bằng chứng để xác định nguyên nhân gốc rễ của các trường hợp missing**.

Do đây là bộ dữ liệu công khai và không có thêm thông tin về nhật ký hệ thống hoặc quy trình xử lý nội bộ, việc tiếp tục điều tra có thể không đem lại kết luận đáng tin cậy hơn.

Vì vậy, quyết định xử lý như sau:

1. **Giữ nguyên giá trị missing:** Không tự điền `order_approved_at` cho 14 đơn hàng vì không có nguồn đáng tin cậy để xác định thời điểm phê duyệt thực tế.
2. **Chuẩn hóa dữ liệu:** Chuyển các giá trị chuỗi rỗng hoặc chỉ chứa khoảng trắng thành `NULL` trong lớp dữ liệu đã làm sạch, đồng thời giữ nguyên dữ liệu staging.
3. **Ghi nhận các bản ghi cần theo dõi:** Lưu danh sách 14 `order_id` cùng thông tin về cột bị thiếu và phát hiện liên quan trong nhật ký chất lượng dữ liệu.
4. **Giới hạn sử dụng trong phân tích:** Không sử dụng những bản ghi thiếu timestamp để tính toán các chỉ số bắt buộc phải có thời điểm phê duyệt hợp lệ. Các bản ghi vẫn được giữ lại trong những phân tích khác mà giá trị thiếu này không cản trở tính chính xác.

**Kết luận cuối cùng:** Các trường hợp missing này được ghi nhận là một vấn đề chất lượng dữ liệu chưa xác định được nguyên nhân. Thay vì suy đoán hoặc tự tạo giá trị thay thế, dự án giữ nguyên thông tin chưa biết và ghi lại quyết định xử lý để đảm bảo tính minh bạch, khả năng kiểm tra và độ tin cậy của những phân tích tiếp theo.



## 2. Phân tích missing values: `order_delivered_carrier_date`

### 2.1. Phát hiện ban đầu

Tiến hành thống kê số lượng giá trị missing của `order_delivered_carrier_date` theo `order_status` trong bảng `staging.olist_orders`.

Kết quả cho thấy các giá trị missing xuất hiện chủ yếu ở những trạng thái như `unavailable`, `canceled`, `invoiced` và `processing`. Đây là những trạng thái mà đơn hàng có thể chưa hoàn tất quá trình vận chuyển hoặc không đi đến bước bàn giao cho đơn vị vận chuyển.

Tuy nhiên, không nên mặc định rằng tất cả các trường hợp missing đều hợp lý chỉ dựa trên trạng thái đơn hàng. Cần tiếp tục kiểm tra những trường hợp có dấu hiệu không nhất quán với các mốc thời gian được ghi nhận.

Đáng chú ý, trong tổng số 625 đơn hàng có trạng thái `canceled`, có 550 đơn bị thiếu `order_delivered_carrier_date`, nhưng vẫn còn **75 đơn có thông tin ngày bàn giao cho đơn vị vận chuyển**. Đây là nhóm cần được kiểm tra thêm.

### 2.2. Kiểm tra mối liên hệ với phương thức thanh toán

Để xác định liệu 75 đơn hàng `canceled` có ngày bàn giao có liên quan đến một phương thức thanh toán cụ thể hay không, tiến hành đối chiếu với bảng `staging.olist_order_payments`.

Kết quả ban đầu cho thấy `credit_card` là phương thức thanh toán phổ biến nhất trong nhóm này. Tuy nhiên, khi so sánh với các đơn hàng `delivered`, phương thức `credit_card` cũng chiếm tỷ trọng lớn.

Do đó, việc `credit_card` xuất hiện nhiều trong nhóm đơn bất thường chưa phải là bằng chứng cho thấy phương thức thanh toán này có liên quan đến vấn đề dữ liệu. Kết quả có thể đơn giản phản ánh mức độ phổ biến của phương thức thanh toán này trong tập dữ liệu.

**Kết luận:** Chưa tìm thấy bằng chứng đủ thuyết phục cho thấy phương thức thanh toán là yếu tố giải thích tình trạng 75 đơn `canceled` vẫn có `order_delivered_carrier_date`. Không tiếp tục đào sâu theo hướng này nếu chưa xuất hiện thêm giả thuyết hoặc thông tin mới.

### 2.3. Kiểm tra phân bố thời gian bàn giao

Tiếp tục kiểm tra thời điểm `order_delivered_carrier_date` của 75 đơn hàng để xác định liệu chúng có tập trung vào một khoảng thời gian bất thường hay không.

Theo kết quả truy vấn, các mốc thời gian bàn giao được ghi nhận tập trung vào tháng 10/2016 và quý I/2018, trong khi không ghi nhận trường hợp nào thuộc năm 2017.

Phân bố thời gian này là một đặc điểm đáng lưu ý của nhóm dữ liệu. Tuy nhiên, chỉ riêng việc các mốc thời gian tập trung vào một số khoảng thời gian nhất định chưa đủ để xác định nguyên nhân. Chưa thể kết luận đây là lỗi hệ thống, vấn đề đồng bộ trạng thái đơn hàng hay một quy trình nghiệp vụ đặc biệt.

### 2.4. Đối chiếu ngày đặt hàng và ngày bàn giao

Để đánh giá tính hợp lý của các mốc thời gian, tiếp tục so sánh `order_purchase_timestamp` với `order_delivered_carrier_date`.

Kết quả cho thấy khoảng cách giữa ngày đặt hàng và ngày bàn giao chủ yếu nằm trong khoảng 1–6 ngày. Có hai đơn hàng có ngày đặt hàng và ngày bàn giao trùng nhau theo ngày lịch.

Những trường hợp này chưa đủ để khẳng định dữ liệu sai lệch. Việc đặt hàng và bàn giao trong cùng ngày có thể xảy ra, nhưng cần xét đến giờ cụ thể và quy trình xử lý thực tế mới có thể đánh giá chính xác hơn.

Do đó, kết quả kiểm tra này chưa cung cấp bằng chứng rõ ràng để xác định nguyên nhân của 75 đơn hàng bất thường.

### 2.5. Đối chiếu với ngày giao hàng cho khách

Tiếp tục kiểm tra `order_delivered_customer_date` trong nhóm 75 đơn hàng `canceled` có `order_delivered_carrier_date`.

Kết quả cho thấy:

- **69 đơn hàng** không có `order_delivered_customer_date`.
- **6 đơn hàng** có cả `order_delivered_carrier_date` và `order_delivered_customer_date`, mặc dù trạng thái hiện tại là `canceled`.

Đây là phát hiện đáng chú ý hơn vì những đơn hàng này có dấu thời gian ghi nhận cả quá trình bàn giao và giao hàng đến khách, trong khi trạng thái đơn hàng vẫn là `canceled`.

Một số khả năng có thể được đặt ra, chẳng hạn đơn bị hủy sau khi đã bàn giao, trạng thái đơn hàng chưa phản ánh đầy đủ diễn biến thực tế hoặc dữ liệu được ghi nhận không nhất quán. Tuy nhiên, dữ liệu hiện có chưa đủ để xác minh khả năng nào đã xảy ra.

Sáu đơn hàng này sẽ được ghi nhận để tiếp tục đối chiếu khi phân tích `order_delivered_customer_date`, thay vì cố gắng kết luận nguyên nhân ngay trong phần kiểm tra cột hiện tại.

### 2.6. Kiểm tra độ đầy đủ của dữ liệu thanh toán và đối chiếu với Excel

Trong quá trình điều tra, ban đầu có giả thuyết rằng chỉ những đơn hàng đã thanh toán mới xuất hiện thông tin `order_delivered_carrier_date`. Tuy nhiên, việc đối chiếu giữa bảng đơn hàng và bảng thanh toán cho thấy giả thuyết này chưa được chứng minh; thông tin thanh toán không đủ để giải thích toàn bộ cách các mốc thời gian vận chuyển được ghi nhận.

Ngoài ra, quá trình kiểm tra bằng SQL phát hiện hai đơn hàng `delivered` bị thiếu `order_delivered_carrier_date`. Việc lọc dữ liệu trong Excel ban đầu không giúp nhận diện các trường hợp này, nhưng kiểm tra lại cho thấy cả hai thực sự bị thiếu giá trị.

Phát hiện này nhấn mạnh sự cần thiết phải kiểm tra dữ liệu một cách nhất quán giữa các công cụ, đặc biệt khi dữ liệu có thể chứa `NULL`, chuỗi rỗng hoặc giá trị chỉ gồm khoảng trắng. Trong lớp dữ liệu đã làm sạch, các dạng giá trị trống này cần được chuẩn hóa để thống kê missing chính xác hơn.

### 2.7. Kết luận và quyết định xử lý

Qua quá trình điều tra, nhận diện được hai vấn đề chính:

1. Phần lớn các giá trị missing của `order_delivered_carrier_date` tập trung ở những trạng thái mà đơn hàng có thể chưa đi đến bước bàn giao cho đơn vị vận chuyển. Tuy nhiên, cần xem xét theo từng trạng thái thay vì mặc định tất cả trường hợp đều hợp lý.
2. Có 75 đơn hàng `canceled` vẫn có ngày bàn giao, trong đó 6 đơn hàng còn có cả ngày giao đến khách. Các kiểm tra bổ sung chưa đủ để xác định nguyên nhân gốc rễ.

Đối với hai đơn hàng `delivered` bị thiếu `order_delivered_carrier_date`, đây cũng là những trường hợp cần được ghi nhận như một vấn đề chất lượng dữ liệu chưa có lời giải thích chắc chắn.

Quyết định xử lý:

- **Không tự điền ngày bàn giao còn thiếu:** Không có căn cứ đáng tin cậy để xác định giá trị thực tế của các timestamp bị thiếu.
- **Chuẩn hóa các giá trị trống trong lớp dữ liệu đã làm sạch:** Chuyển chuỗi rỗng hoặc chuỗi chỉ chứa khoảng trắng thành `NULL`, đồng thời giữ nguyên dữ liệu staging.
- **Không tự ý xóa timestamp hoặc thay đổi `order_status`:** Giữ nguyên các giá trị hiện có của 75 đơn hàng bất thường và ghi nhận để đối chiếu trong những bước phân tích tiếp theo.
- **Tiếp tục theo dõi 6 đơn hàng có ngày giao đến khách:** Đối chiếu với kết quả phân tích `order_delivered_customer_date` để đánh giá tính nhất quán giữa trạng thái đơn hàng và các mốc thời gian.
- **Sử dụng dữ liệu có chọn lọc khi tính KPI:** Chỉ sử dụng những bản ghi có đủ timestamp hợp lệ cho chỉ số đang tính; ghi rõ các điều kiện lọc và số bản ghi bị loại khỏi phép tính nếu có.

**Kết luận cuối cùng:** Không có đủ bằng chứng để xác định nguyên nhân của các trường hợp bất thường liên quan đến `order_delivered_carrier_date`. Vì vậy, dự án giữ nguyên dữ liệu gốc, chuẩn hóa giá trị missing trong lớp dữ liệu đã làm sạch và ghi nhận những trường hợp cần theo dõi. Việc không tự suy đoán timestamp hoặc thay đổi trạng thái đơn hàng giúp đảm bảo tính minh bạch và độ tin cậy của các phân tích tiếp theo.

## 3. Phân tích missing values: `order_delivered_customer_date`

### 3.1. Phát hiện ban đầu

Trong quá trình kiểm tra chất lượng dữ liệu của bảng `staging.olist_orders`, phát hiện ba trường hợp đáng chú ý liên quan đến `order_delivered_customer_date`:

- **`shipped`:** 100% đơn hàng bị thiếu ngày giao đến khách.
- **`canceled`:** Có 6 đơn hàng vẫn ghi nhận ngày giao đến khách.
- **`delivered`:** Có 8 đơn hàng bị thiếu ngày giao đến khách.

Các trường hợp này cần được đánh giá riêng vì missing values và dữ liệu không nhất quán với trạng thái đơn hàng là hai vấn đề khác nhau.

### 3.2. Phân tích các đơn hàng `shipped`

Kết quả thống kê cho thấy toàn bộ đơn hàng có trạng thái `shipped` đều thiếu `order_delivered_customer_date`.

Tiến hành kiểm tra phương thức thanh toán và các mốc thời gian còn lại, bao gồm thời điểm đặt hàng, phê duyệt và bàn giao cho đơn vị vận chuyển. Kết quả không cho thấy dấu hiệu bất thường rõ ràng trong các thông tin thời gian đã được ghi nhận.

Việc thiếu ngày giao đến khách ở nhóm này phù hợp với trạng thái `shipped`: đơn hàng đã được gửi đi nhưng chưa được ghi nhận là đã giao đến khách. Tuy nhiên, trạng thái này không cho biết vị trí thực tế của kiện hàng hoặc liệu việc giao hàng có hoàn tất sau đó hay không.

**Kết luận:** Các giá trị missing ở nhóm `shipped` được xem là phù hợp với ngữ cảnh nghiệp vụ hiện có. Không cần tự điền ngày giao hàng hoặc tiếp tục điều tra sâu nếu không xuất hiện thêm dấu hiệu bất thường.

### 3.3. Phân tích các đơn hàng `canceled` có ngày giao đến khách

Phát hiện 6 đơn hàng có trạng thái `canceled` nhưng vẫn tồn tại `order_delivered_customer_date`. Để đánh giá tính hợp lý của các bản ghi, tiến hành đối chiếu trình tự thời gian giữa thời điểm đặt hàng, phê duyệt, bàn giao cho đơn vị vận chuyển, giao đến khách và ngày giao dự kiến.

Kết quả kiểm tra cho thấy:

- Cả 6 đơn hàng đều có trình tự timestamp hợp lý: đặt hàng trước bàn giao và bàn giao trước ngày giao đến khách.
- Khoảng thời gian từ lúc đặt hàng đến lúc bàn giao dao động từ 1 đến 22 ngày.
- Khoảng thời gian từ lúc bàn giao đến lúc giao đến khách dao động từ 3 đến 29 ngày.
- Có 5 đơn hàng được ghi nhận giao trước ngày dự kiến; 1 đơn được giao sau ngày dự kiến 12 ngày.
- Năm đơn có các mốc thời gian trong tháng 10–11/2016, trong khi đơn còn lại nằm trong tháng 2–3/2018.

Mặc dù trình tự timestamp không có dấu hiệu đảo ngược, việc các đơn hàng có ngày giao đến khách nhưng trạng thái hiện tại là `canceled` vẫn tạo ra sự không nhất quán.

Một số khả năng có thể được đặt ra, chẳng hạn trạng thái đơn hàng không phản ánh đầy đủ diễn biến thực tế hoặc đơn hàng phát sinh vấn đề sau khi giao. Tuy nhiên, dataset không cung cấp lịch sử thay đổi trạng thái và thời điểm hủy đơn, nên chưa thể xác định nguyên nhân chính xác.

**Kết luận:** Đây là 6 trường hợp không nhất quán giữa `order_status` và các mốc thời gian giao hàng, không phải các trường hợp missing. Giữ nguyên timestamp và trạng thái hiện có, đồng thời ghi nhận các `order_id` này để theo dõi trong nhật ký chất lượng dữ liệu.

### 3.4. Phân tích các đơn hàng `delivered` bị thiếu ngày giao đến khách

Phát hiện 8 đơn hàng có trạng thái `delivered` nhưng bị thiếu `order_delivered_customer_date`. Đây là nhóm cần chú ý vì dữ liệu ghi nhận đơn hàng đã được giao đến khách nhưng không có timestamp tương ứng để xác định thời điểm giao hàng thực tế.

Tiến hành đối chiếu các mốc thời gian liên quan và kiểm tra phân bố theo tháng đặt hàng.

Kết quả cho thấy:

| Tháng đặt hàng | Số đơn thiếu ngày giao đến khách | Số đơn đồng thời thiếu ngày bàn giao |
|---|---:|---:|
| 05/2017 | 1 | 1 |
| 11/2017 | 1 | 0 |
| 06/2018 | 3 | 0 |
| 07/2018 | 3 | 0 |
| **Tổng cộng** | **8** | **1** |

Trong 8 đơn hàng:

- **7 đơn** có `order_delivered_carrier_date` nhưng thiếu `order_delivered_customer_date`.
- **1 đơn** thiếu cả ngày bàn giao cho đơn vị vận chuyển và ngày giao đến khách.
- **6/8 đơn** được đặt trong tháng 06–07/2018.

Sự tập trung của 6 trường hợp vào tháng 06–07/2018 là một đặc điểm đáng ghi nhận. Tuy nhiên, chỉ dựa trên số lượng missing chưa đủ để kết luận đây là lỗi hệ thống hoặc một vấn đề mang tính thời kỳ. Muốn xác định liệu tỷ lệ missing có bất thường trong giai đoạn này hay không, cần so sánh với tổng số đơn `delivered` được đặt trong từng tháng.

Đối với một đơn hàng thiếu cả hai mốc thời gian vận chuyển, hiện chưa có đủ thông tin để xác định quá trình giao hàng đã được ghi nhận như thế nào. Với 7 đơn còn lại, dữ liệu xác nhận đã có thời điểm bàn giao nhưng chưa ghi nhận thời điểm giao đến khách.

**Kết luận:** Cả 8 đơn hàng được ghi nhận là các trường hợp missing cần theo dõi. Chưa đủ bằng chứng để xác định nguyên nhân thiếu timestamp, vì vậy không tự điền ngày giao thực tế hoặc sử dụng ngày giao dự kiến thay thế.

### 3.5. Kết luận và quyết định xử lý

Qua quá trình kiểm tra, xác định được ba nhóm dữ liệu có đặc điểm khác nhau:

| Trạng thái | Phát hiện | Đánh giá |
|---|---|---|
| `shipped` | 100% đơn thiếu ngày giao đến khách | Phù hợp với trạng thái được ghi nhận; chưa có dấu hiệu bất thường rõ ràng |
| `canceled` | 6 đơn vẫn có ngày giao đến khách | Không nhất quán giữa trạng thái và timestamp; chưa xác định được nguyên nhân |
| `delivered` | 8 đơn thiếu ngày giao đến khách | Thiếu timestamp cần thiết để xác định thời gian giao hàng thực tế |

Dựa trên kết quả điều tra, quyết định xử lý như sau:

1. **Giữ nguyên các giá trị missing:** Không tự điền `order_delivered_customer_date` khi không có nguồn dữ liệu đáng tin cậy để xác định thời điểm giao hàng thực tế.
2. **Chuẩn hóa dữ liệu:** Chuyển các giá trị chuỗi rỗng hoặc chỉ chứa khoảng trắng thành `NULL` trong lớp dữ liệu đã làm sạch, đồng thời giữ nguyên dữ liệu staging.
3. **Ghi nhận các trường hợp không nhất quán:** Lưu 6 đơn `canceled` có ngày giao đến khách vào nhật ký chất lượng dữ liệu. Không tự ý xóa timestamp hoặc thay đổi trạng thái đơn hàng.
4. **Theo dõi 8 đơn `delivered` bị thiếu timestamp:** Giữ danh sách `order_id` để phục vụ đối chiếu nếu sau này có thêm nguồn dữ liệu.
5. **Giới hạn sử dụng khi tính KPI:** Chỉ tính thời gian giao hàng thực tế trên các đơn có timestamp hợp lệ. Không sử dụng ngày giao dự kiến làm ngày giao thực tế; cần ghi rõ phạm vi và số lượng bản ghi bị loại khỏi phép tính nếu có.

**Kết luận cuối cùng:** Không phải mọi giá trị missing của `order_delivered_customer_date` đều thể hiện lỗi dữ liệu. Nhóm `shipped` có thể được giải thích bằng trạng thái giao hàng chưa được ghi nhận hoàn tất, trong khi 8 đơn `delivered` bị thiếu timestamp và 6 đơn `canceled` vẫn có ngày giao đến khách cần được ghi nhận riêng. Do dữ liệu công khai không cung cấp đủ thông tin để xác minh nguyên nhân, dự án giữ nguyên dữ liệu gốc, không tự suy đoán giá trị thay thế và chỉ loại các bản ghi khỏi những phép tính mà timestamp bị thiếu làm ảnh hưởng đến tính chính xác.