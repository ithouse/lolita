require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe String do
  it "should convert html to text correctly" do
    "simple text".to_text.should == "simple text"
    "<p>Quick brown fox jumps over the lazy dog.</p>".to_text.should == "Quick brown fox jumps over the lazy dog.\n\n"
    "<h1>Title</h1><p>Some text <br /> <strong>some text in bold</strong></p>".to_text.should == "Title\n\nSome text \nsome text in bold\n\n"
    "+---------+---------+\n| name    | surname |\n+---------+---------+\n| Gatis   | Tomsons |\n| Kaspars | Nieks   |\n| Anna    | Liepa   |\n+---------+---------+\n".to_text.should == "+---------+---------+\n| name    | surname |\n+---------+---------+\n| Gatis   | Tomsons |\n| Kaspars | Nieks   |\n| Anna    | Liepa   |\n+---------+---------+\n"
    "<h3>Virsraksts</h3><p>Kaut kāds teksts</p><hr/>".to_text.should == "Virsraksts\n\nKaut kāds teksts\n\n#{"-" * 80}\n"
    %^Sūti e-pastu uz <a href="mailto:none@test.com">none@test.com</a>^.to_text.should == "Sūti e-pastu uz none@test.com"
  end
  
  it "should truncate text correctly" do
    "Pāvests Benedikts XVI svētdien tradicionālajā Lieldienu uzrunā aicināja cilvēci iziet \"garīgu un morālu pārveidi\".".smart_truncate(2000).should == "Pāvests Benedikts XVI svētdien tradicionālajā Lieldienu uzrunā aicināja cilvēci iziet \"garīgu un morālu pārveidi\"."
    "Pāvests Benedikts XVI svētdien tradicionālajā Lieldienu uzrunā aicināja cilvēci iziet \"garīgu un morālu pārveidi\".".smart_truncate(20).should == "Pāvests Benedikts..."
  end
end

